library(admiral)
library(dplyr)
library(pharmaversesdtm)

## KROK 1. Kiedy pacjent rozpoczął leczenie (TRTSDT) -----------

# 1. Przygotowanie danych źródłowych
dm <- pharmaversesdtm::dm
ex <- pharmaversesdtm::ex

# 2. Tworzymy ADSL i wyciągamy datę pierwszej dawki
adsl <- dm |> 
  # Wybieramy tylko niezbędne kolumny z dm
  select(STUDYID, USUBJID, ARM, RFSTDTC, AGE, SEX) |> 
  
  # Używamy funkcji admiral do wyciągnięcia daty z ex
  derive_vars_merged(
    dataset_add = ex,
    new_vars = exprs(TRTSDT = convert_dtc_to_dt(EXSTDTC)),
    filter_add = !is.na(EXSTDTC),
    order = exprs(EXSTDTC),
    mode = "first",
    by_vars = exprs(STUDYID, USUBJID)
  )

# 3. Sprawdzamy wynik
head(adsl)

??derive_vars

## KROK 2: Obliczamy czas trwania leczenia (TRTDURD) ----------------

adsl_extended <- adsl |> 
  # 1. Wyciągamy datę ostatniej dawki (mode = "last")
  derive_vars_merged(
    dataset_add = ex,
    new_vars = exprs(TRTEDT = convert_dtc_to_dt(EXENDTC)),
    filter_add = !is.na(EXENDTC),
    order = exprs(EXENDTC),
    mode = "last",
    by_vars = exprs(STUDYID, USUBJID)
  ) |> 
  # 2. Obliczamy czas trwania w dniach
  derive_vars_duration(
    new_var = TRTDURD,
    start_date = TRTSDT,
    end_date = TRTEDT,
    add_one = TRUE # W klinice start i koniec tego samego dnia to 1 dzień
  )

# Zobaczmy wyniki dla pacjentów, którzy mają obie daty
adsl_extended |> 
  filter(!is.na(TRTDURD)) |> 
  select(USUBJID, TRTSDT, TRTEDT, TRTDURD) |> 
  head()

## Flaga populacji (Safety Population, SAFFL) -------------------------
adsl_final <- adsl_extended |> 
  mutate(SAFFL = if_else(!is.na(TRTSDT), "Y", "N"))

# Sprawdzamy, ilu pacjentów mamy w populacji Safety
table(adsl_final$SAFFL)
