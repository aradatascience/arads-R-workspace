library(Tplyr)

# 1. Definiujemy strukturę tabeli (Table Metadata)
t <- tplyr_table(adsl_final, ARM) |> 
  # Dodajemy warstwę statystyk dla Wieku
  add_layer(
    group_desc(AGE, by = "Wiek (lata)")
  ) |> 
  # Dodajemy warstwę dla płci
  add_layer(
    group_count(SEX, by = "Płeć")
  )

names(adsl_final)
# Dodałam w skrypcie 02 AGE i SEX do adsl

# 2. Budujemy tabelę (tutaj wykonują się obliczenia)
dat <- t |> build()

# 3. Wyświetlamy wynik (czysty dataframe gotowy do formatowania)
dat |> select(starts_with("row"), starts_with("var")) |> head(10)