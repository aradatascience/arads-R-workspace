# Clinical Data Science Workspace

## Opis Projektu
Ten projekt jest moim środowiskiem rozwojowym w obszarze **Clinical Data Science**. 
Skupiam się tutaj na nauce programowania w R zgodnie ze standardami CDISC (ADaM) oraz tworzeniu raportów klinicznych (TFLs).

## Cele nauki
* Tworzenie zbiorów analizowanych (ADSL) przy użyciu pakietu `{admiral}`.
* Generowanie tabel demograficznych i raportów zdarzeń niepożądanych (AE) przy użyciu `{Tplyr}`.
* Automatyzacja powtarzalnych raportów klinicznych.
* Zarządzanie zależnościami projektu za pomocą `{renv}`.

## Struktura folderów
*   `scripts/`: Skrypty R (od eksploracji po generowanie raportów).
*   `outputs/`: Wygenerowane tabele (RTF, PDF, HTML).
*   `logs/`: Logi z procesów przetwarzania danych.
*   `renv/`: Konfiguracja środowiska lokalnego (pakiety).

## Wykorzystane narzędzia (Tech Stack)
* **Język:** R 4.x
* **Standardy:** CDISC ADaM
* **Kluczowe pakiety:**
  * `{tidyverse}` – manipulacja danymi.
  * `{admiral}` – tworzenie zbiorów ADaM.
  * `{Tplyr}` – budowanie tabel klinicznych.

## Jak uruchomić projekt?
1. Sklonuj repozytorium.
2. Otwórz plik `data_science.Rproj`.
3. Uruchom `renv::restore()`, aby zainstalować wszystkie wymagane pakiety w odpowiednich wersjach.
4. Skrypty w folderze `scripts/` są ponumerowane zgodnie z kolejnością analizy.

---
*Projekt ma charakter edukacyjny. Dane wykorzystywane w analizach są syntetyczne (np. pakiet {pharmaversesdtm}) i nie zawierają prawdziwych informacji o pacjentach (PII).*