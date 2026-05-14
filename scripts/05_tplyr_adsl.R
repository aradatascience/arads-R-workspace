# Krok 1. Przygotowanie Tplyr metadata

library(Tplyr)

  # Inicjalizacja tabeli
t <- tplyr_table(adsl, TRT01P) |> # TRT01P to ramię leczenia (Planned Arm)
  add_total_group() |>          # Dodajemy kolumnę Total
  set_pop_data(adsl) |>         # Definiujemy populację
  set_pop_where(SAFFL == "Y")   # Tabela demograficzna zazwyczaj dotyczy populacji SAFETY 
  
# Krok 2. Dodawanie warstw (layers) - dwa rodzaje Count (liczy n i %) i Desc (liczy średnią, medianę, min/max) Layers

t <- t |> 
  # Dodanie warstwy dla Płci (zmienna kategoryczna)
  # Dodajemy precyzję (Precision Rules)
  add_layer(
    group_count(SEX, by = "Sex") |> 
      set_format_strings(
        n_counts = f_str("xx (xx.x%)", n, pct)
      )
  ) |> 
  # Dodanie warstwy dla Wieku (zmienna ciągła)
  add_layer(
    group_desc(AGE, by = "Age (Years)") |> 
      set_format_strings(
        # n: 0 miejsc po przecinku
        # Mean (SD): 1 miejsce dla średniej, 2 dla odchylenia
        # [Min, Max]: bez miejscpo przecinku
        "n"         = f_str("xx", n),
        "Mean (SD)" = f_str("xx.x (xx.xx)", mean, sd),
        "Median"    = f_str("xx.x", median),
        "[Min, Max]"= f_str("[xx, xx]", min, max)
      )
    )|> 
  # Warstwa 3: Grupy wiekowe (te stworzone wcześniej)
  add_layer(
    group_count(AGEGR1, by = "Age Group 1 [n (%)]") |> 
      set_format_strings(
        n_counts = f_str("xx (xx.x%)", n, pct)
      )
  )

# N w nagłówkach - pobieram dane do wektora
counts <- adsl |> count(TRT01P)

n_placebo <- counts |> filter(TRT01P == "Placebo") |> pull(n)
n_scrfail <- counts |> filter(TRT01P == "Screen Failure") |> pull(n)
n_hdose   <- counts |> filter(TRT01P == "Xanomeline High Dose") |> pull(n)
n_ldose   <- counts |> filter(TRT01P == "Xanomeline Low Dose") |> pull(n)
n_total   <- nrow(adsl)

# Krok 3. Budowanie (Build)
result <- t |> build()

# bez tego
result_formatted <- apply_formats(result)

names(result)
class(result) <- "data.frame"

# z tym
result <- result |> 
  # Usuwamy kolumny techniczne 'ord', zostawiamy czytelne
  dplyr::select(row_label1, row_label2, starts_with("var1_Total"), !starts_with("ord"))


View(result)

# Krok 4. Stylizowanie i Eksport przez gt
library(gt)

gt_table <- result |> 
  gt() |> 
  tab_header(
    title = "Table 14.1",
    subtitle = "Summary of Demographic and Baseline Characteristics"
  ) |> 
  cols_label(
    row_label1 = "Characteristic",
    row_label2 = "Variable",
    var1_Placebo = paste0("Placebo\n(N=", n_placebo, ")"),
    'var1_Screen Failure' = paste0("Screen Failure\n(N=", n_scrfail, ")"),
    'var1_Xanomeline High Dose' = paste0("Xanomeline High Dose\n(N=", n_hdose, ")"),
    'var1_Xanomeline Low Dose' = paste0("Xanomeline Low Dose\n(N=", n_ldose, ")"),
    var1_Total = paste0("Total\n(N=", n_total, ")")
  ) |> 
  tab_source_note(
    source_note = paste("Data source: ADSL. Baseline is defined as the last non-missing value prior to first dose. Created on:", Sys.Date())
  ) |> 
  # stylizacja: pogrubienie nagłówków i wyrównanie
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_column_labels()
  ) |> 
  cols_align(align = "left", columns = 1) |> 
  cols_align(align = "center", columns = -1)

# Eksport do RTF
gtsave(gt_table, "outputs/tabela_14_1_demog.rtf")


