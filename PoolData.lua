-- Data: ForeverDB.net (https://foreverdb.net), build 1.60.1.71139. Reuse requires this credit: see NOTICE.txt (GPL-3.0 section 7(b)).
-- Data from ForeverDB.net (https://foreverdb.net), GPL-3.0 with an attribution term. Fishing pool spawn points only, copied from ForeverDB's
-- Data\Gather.lua (built 2026-11-27). c = Classic spawn points (CMaNGOS classic-db, GPL-3.0: may differ in Forever); f = points players saw in WoW Forever.
-- Points: 4 base-36 characters each (x then y, tenths of a percent).
local ADDON_NAME, F = ...
F.POOLS = {
  kinds = {
    [40] = { n = "Patch of Elemental Water", item = 7070 },
    [41] = { n = "Sagefish School", item = 21071 },
    [42] = { n = "School of Deviate Fish", item = 6522 },
    [43] = { n = "School of Fish", item = 0 },
    [44] = { n = "School of Tastyfish", item = 19807 },
    [641] = { n = "Open water", item = 0 },
  },
  zones = {
    [1412] = { skill = 25, k = {
      [641] = { c = "", f = "9k4zc8gyc9htdig3" },
    } },
    [1413] = { skill = 75, k = {
      [42] = { c = "cf6kcj66cj6kcn6bcrb2ctahcvagcvb6cxapd7b8dcb4fcbmfcbwffc1fibtflby", f = "" },
      [641] = { c = "", f = "co6ccxagddb2fec2hke2hpaqhwa1" },
    } },
    [1414] = { skill = 0, k = {
      [641] = { c = "", f = "c79n" },
    } },
    [1416] = { skill = 225, k = {
      [41] = { c = "ixlpjakljtjk", f = "" },
    } },
    [1417] = { skill = 225, k = {
      [641] = { c = "", f = "72er84f3" },
    } },
    [1420] = { skill = 25, k = {
      [641] = { c = "", f = "ine4" },
    } },
    [1421] = { skill = 75, k = {
      [641] = { c = "", f = "9351a06fag8hfs53gk9ogr4rhs99" },
    } },
    [1424] = { skill = 150, k = {
      [41] = { c = "fhfqfne5fydagq8vgt8fgw9hh58yhcbthkbbi4axir9uiu88iy5oj17b", f = "" },
      [641] = { c = "", f = "9jj9aljebrjccsigdxiee1jdf7gvfcf1fdhyfefrfje5ftd6gl8vgu89h893hlbjio9sir87ix7bjv2w" },
    } },
    [1426] = { skill = 25, k = {
      [641] = { c = "", f = "9ub4" },
    } },
    [1429] = { skill = 25, k = {
      [43] = { c = "ez4f", f = "" },
      [641] = { c = "", f = "84op8ph5d6ifdeh8" },
    } },
    [1431] = { skill = 150, k = {
      [641] = { c = "", f = "1jar" },
    } },
    [1432] = { skill = 75, k = {
      [641] = { c = "", f = "bi9pbiatbt5cd06genbdfg7e" },
    } },
    [1433] = { skill = 150, k = {
      [641] = { c = "", f = "5ye76ieu8nduh3jji1jwivjyjfhzkifzkshh" },
    } },
    [1434] = { skill = 225, k = {
      [44] = { c = "5d3u5v4j625566fj6aeo6dfo6f576lhd6sgf6tdv6w5h6wg76xdy6xfn6xie6zg574in75dp77nd78dk7ag77amx7e5m7hnl7icb7kb47kbr7las7lcq7pne7s61806681ah857f887x8c7n8c7u8d7m8gn88ta58tms8wa4909w9c969fln9gkr9lkd9m8y9q9u9ra39vk6a1jva4jgbegu", f = "" },
      [641] = { c = "", f = "68e76ndb7cg97dkh7eng7ice7sl78g858hn39p2wac2vb04yb448" },
    } },
    [1436] = { skill = 75, k = {
      [641] = { c = "", f = "6ufn72gd78c47db87o987skh7xlt8j7m8jnj95nd9zoxe02mf42i" },
    } },
    [1437] = { skill = 150, k = {
      [641] = { c = "", f = "19fw1dhk28g82dgx3j9x3m98993admak" },
    } },
    [1438] = { skill = 25, k = {
      [641] = { c = "", f = "f9qw" },
    } },
    [1439] = { skill = 75, k = {
      [641] = { c = "", f = "8gbc8zc697b59xcka0fha1jea1kla2eba4hvajbqao8rbekrbl6ybo7xbr5te66hef7peu90" },
    } },
    [1440] = { skill = 150, k = {
      [41] = { c = "9qd79tcw9uf39yeva3euakdtaudab0elcfjjcxj1d2j9d7jsdhixdhjndlizeojwhljkhrj6krcoldcvltk6lyf8lyfnm0j7nnij", f = "" },
      [641] = { c = "", f = "319e3d4g5lbu9hiiccf4cnd3dfjldmiyhjjjlwfllyj7" },
    } },
    [1442] = { skill = 150, k = {
      [641] = { c = "", f = "cvh1dec1e0bbhgcrifexiicbj2edjoeqkafq" },
    } },
    [1443] = { skill = 225, k = {
      [641] = { c = "", f = "66kb" },
    } },
    [1445] = { skill = 225, k = {
      [641] = { c = "", f = "i0b5jwfn" },
    } },
    [1447] = { skill = 300, k = {
      [40] = { c = "f6aufge7gpb1ifj1kqk6m0f4", f = "" },
    } },
    [1450] = { skill = 300, k = {
      [641] = { c = "", f = "fqazgteu" },
    } },
    [1453] = { skill = 75, k = {
      [641] = { c = "", f = "547g67fh79d5c8kaf6k7f9izfml8fqjzg2m1i1h1ifhnirp7ixgyj8ibjiedl0ns" },
    } },
    [1454] = { skill = 75, k = {
      [641] = { c = "", f = "ahmfir7yjd8ejf9wjt8z" },
    } },
    [1456] = { skill = 75, k = {
      [641] = { c = "", f = "bng5" },
    } },
    [1457] = { skill = 75, k = {
      [641] = { c = "", f = "bscgd9fq" },
    } },
    [1458] = { skill = 75, k = {
      [641] = { c = "", f = "g6j0ko6tmj8u" },
    } },
    [2521] = { skill = 0, k = {
      [641] = { c = "", f = "d0dlf5lihdkz" },
    } },
    [2548] = { skill = 0, k = {
      [641] = { c = "", f = "aze2c1f5kzi6m3f7" },
    } },
  },
}
