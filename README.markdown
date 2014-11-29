Skrypt normalizujący dane o wolontariuszach do [wspólnego formatu](https://github.com/Krakow2016/river/wiki/Format) na potrzeby zcentralizowanej bazy danych.

## Użycie

    $ perl scripts/river.pl paper.csv internetowe.csv | curl localhost:9200/sdm/volounteer/_bulk --data-binary @-
