# Tworzenie wielu folderów
folders <- c("data", "scripts", "outputs", "logs")
lapply(folders, dir.create)

# instalowanie pakietów ---------------------------------------
install.packages(c(
  "tidyverse",    # Praca z danymi
  "admiral",      # Tworzenie zbiorów ADaM
  "Tplyr",        # Tabele kliniczne
  "survival",     # Analizy przeżycia
  "gtsummary",    # Tabele statystyczne
  "pharmaversesdtm", # Przykładowe dane kliniczne do nauki
  "sdtm.oak"        #Mapowanie SDTM
))


# instalowanie oak (ale jednak nazwa to stdm.oak) z repozytorium Pharmaverse
# najpierw potrzebny pakiet remotes

if (!require("remotes")) install.packages("remotes")
remotes::install_github("pharmaverse/sdtm.oak")

# drugi sposób z oak (pakiet pak)
install.packages("pak")
pak::pkg_install("pharmaverse/sdtm.oak")

# restart cmd + shift + 0
renv::activate()

# załadowanie bibliotek ---------------------------------------------------
library(tidyverse)
library(admiral)
library(Tplyr)
library(survival)
library(gtsummary)
library(pharmaversesdtm)
library(sdtm.oak)

# renv ------------------------------------------------
# podgląd czy wszystkie pakiety zapisane
renv::status()
# aktualizacja
renv::snapshot()
# gdy coś popsuję
renv::restore()

# dane ------------------------------------------------
# załadowanie danych demograficznych
dm <- pharmaversesdtm::dm
head(dm)

table(dm$SEX)
names(dm)
glimpse(dm)
