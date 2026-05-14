# przydatne ----------------------------------------
library(admiral)
admiral::use_ad_template("adsl")
admiral::list_all_templates()
glimpse(admiral_adsl)


# GET STARTED (pharmaverse.org/admiral) --------------
# Uncomment line below if you need to install these packages
# install.packages(c("dplyr", "lubridate", "stringr", "tibble", "pharmaversesdtm", "admiral"))

library(tidyverse)
library(pharmaversesdtm)
library(admiral)

# Read in SDTM datasets
dm <- pharmaversesdtm::dm
ds <- pharmaversesdtm::ds
ex <- pharmaversesdtm::ex
vs <- pharmaversesdtm::vs
admiral_adsl <- admiral::admiral_adsl

glimpse(admiral_adsl)

admiral::use_ad_template(
  adam_name = "adsl",
  save_path = "./ad_adsl.R"
)

## ADMIRAL nauka tworzenia ADSL -------------------------

library(admiral)
library(tidyverse)
library(pharmaversesdtm)

renv::status()

## Krok 1. Start: bierzemy surowe dane (wybór szkieletu)

dm <- pharmaversesdtm::dm
ex <- pharmaversesdtm::ex
ds <- pharmaversesdtm::ds
glimpse(ds)
table(ds$DSDECOD)

adsl <- dm |> 
  select(STUDYID, USUBJID, SUBJID, ARM, ACTARM, RFSTDTC, BRTHDTC, SEX)

## Krok 2. Dodajemy datę pierwszej dawki ze zbioru EX (podstawa pod SAFFL)
adsl <- adsl |> 
  derive_vars_merged(
    dataset_add = ex,
    by_vars = exprs(STUDYID, USUBJID),
    new_vars = exprs(TRTSDT = convert_dtc_to_dt(EXSTDTC)),
    filter_add = !is.na(EXSTDTC),
    order = exprs(EXSTDTC),
    mode = "first"
  ) |> 
  # i dodajemy datę ostatniej dawki 
  # Dane o zakończeniu badania (Disposition - DS)
  derive_vars_merged(
    dataset_add = ds,
    by_vars = exprs(STUDYID, USUBJID),
    new_vars = exprs(
      EOSDT = convert_dtc_to_dt(DSSTDTC), 
      DSDECOD_EOS = DSDECOD
      ),
    # Filtr: bierzemy zdarzenia typu Disposition
    # ale pomijamy wejścia do badania i screening (Randomized i Screeen Failure)
    filter_add = DSCAT == "DISPOSITION EVENT" & 
      !(DSDECOD %in% c("RANDOMIZED", "SCREEN FAILURE"))
  )

## Krok 3. Flagi
adsl <- adsl |> 
  mutate(
    # Flaga: Czy pacjent zakończył badanie?
    EOSFL = if_else(!is.na(EOSDT), "Y", "N"),
    # Flaga: Czy ukończył badanie sukcesem?
    COMPLFL = if_else(DSDECOD_EOS == "COMPLETED", "Y", "N")
  )

## Krok 4. Robimy wszystkie obliczenia
adsl <- adsl |> 
  mutate(
    # Konwersja dat (ISO 8601 do formatu R)
    # Zmieniamy tekstową datę rozpoczęcia badania na datę R
    RFSTDT = convert_dtc_to_dt(RFSTDTC),
    # Zmieniamy datę urodzenia
    BRTHDT = convert_dtc_to_dt(BRTHDTC),
    
    # Tworzymy obie flagi populacji (Zmienne typu "Y/N")
    # ITTFL - bo ma ramię leczenia (Intent-to-treat population flag)
    ITTFL = if_else(!is.na(ARM) & ARM != "Screen Failure", "Y", "N"),
    
    # SAFETY - bo wiemy, że wziął lek (ma datę TRTSDT)
    SAFFL = if_else(!is.na(TRTSDT), "Y", "N")
  ) |> 
  
  # Dodanie planowanego leczenia
  # TRT01P - Planned Treatment for Period 01
  mutate(TRT01P = ARM,
         TRT01A = ACTARM) |> 
  
  ## Pierwsza ważna operacja (Derivation)
  # Obliczamy wiek analityczny pacjenta (AGE)
  derive_vars_duration(
    new_var = AGE,
    start_date = BRTHDT,
    end_date = TRTSDT, # wiek w dniu podania leku
    out_unit = "years",
    add_one = FALSE
  ) |> 
  mutate(AGE = floor(AGE)) # zaokrąglanie w dół

# Sprawdzamy co mamy
glimpse(adsl)

# WARTO sprawdzać po ważnych obliczeniach
summary(adsl$AGE)
# Sprawdzenie dlaczego nie wszyscy mają TRTAGE
adsl |> 
  filter(is.na(AGE)) |> 
  select(USUBJID, BRTHDT, RFSTDT, AGE)
# Gdzie brakuje dat
adsl |> 
  filter(is.na(BRTHDT))
adsl |> 
  filter(is.na(AGE))
# IMPUTACJA
# GDYBY w datach brakowało dni (nie brakuje) robimy IMPUTACJĘ
adsl <-  adsl |> 
  mutate(
    RFSTDT = convert_dtc_to_dt(RFSTDTC, highest_imputation = "D"),
    BRTHDT = convert_dtc_to_dt(BRTHDTC, highest_imputation = "D")
  )
# Sprawdzam czy brak daty RFSTDT jest dla pacjentów z ARM "screen failure"
adsl |> 
  filter(is.na(RFSTDT)) |> 
  count(ARM)


## Krok 5. Grupowanie (kategoryzacja)
# AGEGR1 - to podział wymagany przez FDA
# Sposób 1 - case_when() - do wieku to najlepsze
adsl <- adsl |> 
  mutate(
    AGEGR1 = case_when(
      AGE < 65 ~ "< 65 lat",
      AGE >= 65 ~ ">= 65 lat",
      is.na(AGE) ~ "Missing"
    ),
    # Wersja numeryczna do sortowania
    AGEGR1N = case_when(
      AGEGR1 == "< 65 lat" ~ 1,
      AGEGR1 == ">= 65 lat" ~ 2,
      AGEGR1 == "Missing" ~ 3
    )
  )

# Sposób 2 - NIE UZYWAM TERAZ - derive_vars_cat()
# Definiujemy warunki (definition)
age_group_definition <- list(
  exprs(AGEGR1 = "< 65", condition = AGE < 65),
  exprs(AGEGR1 = ">= 65", condition = AGE >= 65)
)

glimpse(adsl)

## Krok 6. Przygotowanie danych do standardu SAS (.xpt, SAS transport file)
# Nazwy kolumn max 8 znaków
# Etykiety (Labels)

# sposób 1:
library(haven)

# Sprawdzenie co ma etykiety
map(adsl_to_export, attr, "label")

# sposób 2: LEPSZY
install.packages("labelled")
renv::snapshot()

library(labelled)

colnames(adsl)

adsl <- adsl |> 
  set_variable_labels(
    STUDYID     = "Study Identifier",
    USUBJID     = "Unique Subject Identifier",
    SUBJID      = "Subject Identifier",
    ARM         = "Description of Planned Arm",
    ACTARM      = "Description of Actual Arm",
    RFSTDTC     = "Subject Reference Start Date/Time",
    BRTHDTC     = "Date/Time of Birth",
    SEX         = "Sex",
    TRTSDT      = "Date of First Exposure to Treatment",
    EOSDT       = "End of Study Date",
    DSDECOD_EOS = "End of Study Status (Protocol Reason)",
    EOSFL       = "End of Study Flag",
    COMPLFL     = "Completers Population Flag",
    RFSTDT      = "Subject Reference Start Date",
    BRTHDT      = "Date of Birth",
    ITTFL       = "Intent-To-Treat Population Flag",
    SAFFL       = "Safety Population Flag",
    TRT01P      = "Planned Treatment for Period 01",
    TRT01A      = "Actual Treatment for Period 01",
    AGE         = "Age",
    AGEGR1      = "Analysis Age Group 1",
    AGEGR1N     = "Analysis Age Group 1 (N)"
  )

# SPRAWDZENIE ostateczne:
# klasy (typy) zmiennych
glimpse(adsl)
# podsumowanie flag - czy pacjenci poprawnie przypisani
table(adsl$ITTFL, adsl$ARM)
# wiek czy logiczny zakres ma
min(adsl$AGE, na.rm = TRUE)
max(adsl$AGE, na.rm = TRUE)

## Krok 8. EKSPORT
library(haven)
write_xpt(adsl, "outputs/adsl.xpt")
View(adsl)
message("Sukces!")

