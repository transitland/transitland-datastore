# Change Log

## [v82](https://github.com/transitland/transitland-datastore/tree/v82) (2018-05-18)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/81...v82)

**Fixed bugs:**

- Net::SMTPFatalError: 550 5.7.1 Unconfigured Sending Domain \<mapzen.com\> [\#1231](https://github.com/transitland/transitland-datastore/issues/1231)

**Merged pull requests:**

- CircleCI: build container image on tag [\#1237](https://github.com/transitland/transitland-datastore/pull/1237) ([drewda](https://github.com/drewda))
- CircleCI 2.0, continued again [\#1236](https://github.com/transitland/transitland-datastore/pull/1236) ([drewda](https://github.com/drewda))
- CircleCI 2.0, continued [\#1235](https://github.com/transitland/transitland-datastore/pull/1235) ([drewda](https://github.com/drewda))
- \[WIP\] Production release 82 [\#1234](https://github.com/transitland/transitland-datastore/pull/1234) ([drewda](https://github.com/drewda))
- \[WIP\] CircleCI to build Docker image [\#1233](https://github.com/transitland/transitland-datastore/pull/1233) ([drewda](https://github.com/drewda))
- configure SMTP settings through ENV vars [\#1232](https://github.com/transitland/transitland-datastore/pull/1232) ([drewda](https://github.com/drewda))
- update gems [\#1230](https://github.com/transitland/transitland-datastore/pull/1230) ([drewda](https://github.com/drewda))
- Send change\_payload created\_at and update\_at in API response. [\#1228](https://github.com/transitland/transitland-datastore/pull/1228) ([Rui-Santos](https://github.com/Rui-Santos))
- update misc. gems [\#1227](https://github.com/transitland/transitland-datastore/pull/1227) ([drewda](https://github.com/drewda))
- Production release [\#1224](https://github.com/transitland/transitland-datastore/pull/1224) ([irees](https://github.com/irees))

## [81](https://github.com/transitland/transitland-datastore/tree/81) (2018-03-13)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/push...81)

## [push](https://github.com/transitland/transitland-datastore/tree/push) (2018-03-13)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/80...push)

**Merged pull requests:**

- Update gems [\#1225](https://github.com/transitland/transitland-datastore/pull/1225) ([irees](https://github.com/irees))
- Fix issue with FeedFetcher batches [\#1223](https://github.com/transitland/transitland-datastore/pull/1223) ([irees](https://github.com/irees))
- AWS ECS Deploy [\#1220](https://github.com/transitland/transitland-datastore/pull/1220) ([irees](https://github.com/irees))
- Production release 81 [\#1218](https://github.com/transitland/transitland-datastore/pull/1218) ([irees](https://github.com/irees))

## [80](https://github.com/transitland/transitland-datastore/tree/80) (2018-01-13)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/79...80)

**Implemented enhancements:**

- Tile Export [\#1210](https://github.com/transitland/transitland-datastore/issues/1210)

**Closed issues:**

- OperatorsInFeed: Make copy in FeedVersionImport before import [\#1207](https://github.com/transitland/transitland-datastore/issues/1207)
- Skip fetching for certain "status" tags [\#1204](https://github.com/transitland/transitland-datastore/issues/1204)
- Station merging: all SSPs on platforms [\#1199](https://github.com/transitland/transitland-datastore/issues/1199)

**Merged pull requests:**

- Sidekiq cron [\#1219](https://github.com/transitland/transitland-datastore/pull/1219) ([irees](https://github.com/irees))
- Feed version ordering [\#1217](https://github.com/transitland/transitland-datastore/pull/1217) ([irees](https://github.com/irees))
- Docker improvements [\#1216](https://github.com/transitland/transitland-datastore/pull/1216) ([irees](https://github.com/irees))
- Tile export debug 3 [\#1215](https://github.com/transitland/transitland-datastore/pull/1215) ([irees](https://github.com/irees))
- Move enqueue feed versions to 6pm PST / 8pm CST / 2am GMT [\#1213](https://github.com/transitland/transitland-datastore/pull/1213) ([irees](https://github.com/irees))
- Tile export - additional debugging [\#1212](https://github.com/transitland/transitland-datastore/pull/1212) ([irees](https://github.com/irees))
- Tile export refinements [\#1211](https://github.com/transitland/transitland-datastore/pull/1211) ([irees](https://github.com/irees))
- misc. gem updates [\#1209](https://github.com/transitland/transitland-datastore/pull/1209) ([drewda](https://github.com/drewda))
- OperatorsInFeed: Make copy in FeedVersionImport before import [\#1208](https://github.com/transitland/transitland-datastore/pull/1208) ([irees](https://github.com/irees))
- Feed status: skip fetching if not active [\#1206](https://github.com/transitland/transitland-datastore/pull/1206) ([irees](https://github.com/irees))
- Debug: revert station ssp [\#1205](https://github.com/transitland/transitland-datastore/pull/1205) ([irees](https://github.com/irees))
- update misc. gems [\#1203](https://github.com/transitland/transitland-datastore/pull/1203) ([drewda](https://github.com/drewda))
- Production release 80 [\#1202](https://github.com/transitland/transitland-datastore/pull/1202) ([irees](https://github.com/irees))
- Tile export [\#1201](https://github.com/transitland/transitland-datastore/pull/1201) ([irees](https://github.com/irees))
- Production release 79 [\#1198](https://github.com/transitland/transitland-datastore/pull/1198) ([irees](https://github.com/irees))

## [79](https://github.com/transitland/transitland-datastore/tree/79) (2017-10-12)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/78...79)

**Closed issues:**

- Use gtfs auto\_detect\_root: true [\#1073](https://github.com/transitland/transitland-datastore/issues/1073)

**Merged pull requests:**

- Station SSPs [\#1200](https://github.com/transitland/transitland-datastore/pull/1200) ([irees](https://github.com/irees))
- Production release 78 [\#1195](https://github.com/transitland/transitland-datastore/pull/1195) ([irees](https://github.com/irees))

## [78](https://github.com/transitland/transitland-datastore/tree/78) (2017-10-03)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/77...78)

**Implemented enhancements:**

- Configurable SSL verify mode [\#1185](https://github.com/transitland/transitland-datastore/issues/1185)

**Closed issues:**

- sort\_by vs. sort\_key [\#1193](https://github.com/transitland/transitland-datastore/issues/1193)
- Changesets: examine array uniqueness requirements [\#1059](https://github.com/transitland/transitland-datastore/issues/1059)

**Merged pull requests:**

- Add auto\_detect\_root to GTFS open [\#1197](https://github.com/transitland/transitland-datastore/pull/1197) ([irees](https://github.com/irees))
- update misc. gems [\#1196](https://github.com/transitland/transitland-datastore/pull/1196) ([drewda](https://github.com/drewda))
- Configurable SSL validation [\#1194](https://github.com/transitland/transitland-datastore/pull/1194) ([irees](https://github.com/irees))
- Production release 77 [\#1178](https://github.com/transitland/transitland-datastore/pull/1178) ([irees](https://github.com/irees))

## [77](https://github.com/transitland/transitland-datastore/tree/77) (2017-09-26)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/76...77)

**Implemented enhancements:**

- Feeds: import\_policy [\#1085](https://github.com/transitland/transitland-datastore/issues/1085)

**Fixed bugs:**

- Validation reports: file not found [\#1154](https://github.com/transitland/transitland-datastore/issues/1154)

**Closed issues:**

- FeedFetcher: Basic validation of new feeds [\#1191](https://github.com/transitland/transitland-datastore/issues/1191)
- Feed Publication Metrics [\#1183](https://github.com/transitland/transitland-datastore/issues/1183)
- Validation reports: timeout [\#1180](https://github.com/transitland/transitland-datastore/issues/1180)
- Keyset pagination: check for result before generating next url [\#1176](https://github.com/transitland/transitland-datastore/issues/1176)

**Merged pull requests:**

- Feed update statistics fixes [\#1192](https://github.com/transitland/transitland-datastore/pull/1192) ([irees](https://github.com/irees))
- Feed\#import\_policy also checks manual\_import tag [\#1190](https://github.com/transitland/transitland-datastore/pull/1190) ([irees](https://github.com/irees))
- update gems [\#1189](https://github.com/transitland/transitland-datastore/pull/1189) ([drewda](https://github.com/drewda))
- Improve FeedVersion creation [\#1188](https://github.com/transitland/transitland-datastore/pull/1188) ([irees](https://github.com/irees))
- Feed import policy [\#1186](https://github.com/transitland/transitland-datastore/pull/1186) ([irees](https://github.com/irees))
- Feed Publication Metrics [\#1184](https://github.com/transitland/transitland-datastore/pull/1184) ([irees](https://github.com/irees))
- updating URLs in sample changesets [\#1182](https://github.com/transitland/transitland-datastore/pull/1182) ([drewda](https://github.com/drewda))
- update misc. gems [\#1181](https://github.com/transitland/transitland-datastore/pull/1181) ([drewda](https://github.com/drewda))
- Fix validator missing file and add validator timeouts [\#1179](https://github.com/transitland/transitland-datastore/pull/1179) ([irees](https://github.com/irees))
- Production release 76 [\#1175](https://github.com/transitland/transitland-datastore/pull/1175) ([irees](https://github.com/irees))

## [76](https://github.com/transitland/transitland-datastore/tree/76) (2017-08-28)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/75...76)

**Merged pull requests:**

- Check for result before next url [\#1177](https://github.com/transitland/transitland-datastore/pull/1177) ([irees](https://github.com/irees))
- Production release 75 [\#1167](https://github.com/transitland/transitland-datastore/pull/1167) ([irees](https://github.com/irees))

## [75](https://github.com/transitland/transitland-datastore/tree/75) (2017-08-22)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/74...75)

**Closed issues:**

- SSP controller: avoid expensive subqueries [\#1173](https://github.com/transitland/transitland-datastore/issues/1173)
- Pagination: keyset [\#1170](https://github.com/transitland/transitland-datastore/issues/1170)
- Next url: include apikey [\#1168](https://github.com/transitland/transitland-datastore/issues/1168)

**Merged pull requests:**

- Query params: apikey [\#1174](https://github.com/transitland/transitland-datastore/pull/1174) ([irees](https://github.com/irees))
- SSP controller: avoid expensive subqueries [\#1172](https://github.com/transitland/transitland-datastore/pull/1172) ([irees](https://github.com/irees))
- Implement keyset pagination [\#1171](https://github.com/transitland/transitland-datastore/pull/1171) ([irees](https://github.com/irees))
- Update gems and annotations [\#1169](https://github.com/transitland/transitland-datastore/pull/1169) ([drewda](https://github.com/drewda))
- Production release 74 [\#1157](https://github.com/transitland/transitland-datastore/pull/1157) ([irees](https://github.com/irees))

## [74](https://github.com/transitland/transitland-datastore/tree/74) (2017-08-14)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/73...74)

**Implemented enhancements:**

- include more information/columns when requesting CSV from API endpoints [\#1164](https://github.com/transitland/transitland-datastore/issues/1164)

**Closed issues:**

- Relax JSON Schema array uniqueness requirements [\#1159](https://github.com/transitland/transitland-datastore/issues/1159)
- Remove old SSPs [\#1156](https://github.com/transitland/transitland-datastore/issues/1156)
- Stop becomes StopPlatform [\#1152](https://github.com/transitland/transitland-datastore/issues/1152)
- Feeds: feed\_versions default ordering by service\_start\_date [\#1144](https://github.com/transitland/transitland-datastore/issues/1144)
- Feed: Add a 'name' field [\#1131](https://github.com/transitland/transitland-datastore/issues/1131)
- Query for Operators without Feeds [\#1130](https://github.com/transitland/transitland-datastore/issues/1130)

**Merged pull requests:**

- update misc. gems [\#1166](https://github.com/transitland/transitland-datastore/pull/1166) ([drewda](https://github.com/drewda))
- CSV additions [\#1165](https://github.com/transitland/transitland-datastore/pull/1165) ([drewda](https://github.com/drewda))
- SSP: Skip trip if interpolation issues [\#1163](https://github.com/transitland/transitland-datastore/pull/1163) ([irees](https://github.com/irees))
- Feed: add name [\#1162](https://github.com/transitland/transitland-datastore/pull/1162) ([irees](https://github.com/irees))
- Operators: with\_feed and without\_feed [\#1161](https://github.com/transitland/transitland-datastore/pull/1161) ([irees](https://github.com/irees))
- Relax JSON Schema "uniqueItems" requirements [\#1160](https://github.com/transitland/transitland-datastore/pull/1160) ([irees](https://github.com/irees))
- Feed: sort feed\_versions by earliest\_calendar\_date [\#1158](https://github.com/transitland/transitland-datastore/pull/1158) ([irees](https://github.com/irees))
- Changeset: changeStopType action [\#1155](https://github.com/transitland/transitland-datastore/pull/1155) ([irees](https://github.com/irees))
- Production release 73 [\#1140](https://github.com/transitland/transitland-datastore/pull/1140) ([irees](https://github.com/irees))

## [73](https://github.com/transitland/transitland-datastore/tree/73) (2017-08-03)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/72...73)

**Closed issues:**

- RSP: Use stop centroids [\#1148](https://github.com/transitland/transitland-datastore/issues/1148)
- Use 64 bit ID for SSP [\#1141](https://github.com/transitland/transitland-datastore/issues/1141)
- SSP: Query by operator\_onestop\_id is slow [\#1138](https://github.com/transitland/transitland-datastore/issues/1138)
- Polygons \(not just points\) for StopStation geometries [\#826](https://github.com/transitland/transitland-datastore/issues/826)
- consistent precision for geometries [\#362](https://github.com/transitland/transitland-datastore/issues/362)

**Merged pull requests:**

- Gracefully handle references to missing stop or route [\#1153](https://github.com/transitland/transitland-datastore/pull/1153) ([irees](https://github.com/irees))
- Stop: fallback to stop\_id if stop\_name is not present [\#1151](https://github.com/transitland/transitland-datastore/pull/1151) ([irees](https://github.com/irees))
- Stop serializer: use geometry\_centroid not centroid [\#1150](https://github.com/transitland/transitland-datastore/pull/1150) ([irees](https://github.com/irees))
- Include geometry\_reversegeo and centroid in Stop and Station serializers [\#1149](https://github.com/transitland/transitland-datastore/pull/1149) ([irees](https://github.com/irees))
- RSP: Fixes for stops with polygon geometries [\#1147](https://github.com/transitland/transitland-datastore/pull/1147) ([irees](https://github.com/irees))
- Tidy up: schema & annotation update [\#1146](https://github.com/transitland/transitland-datastore/pull/1146) ([irees](https://github.com/irees))
- Cleanup: Alter SSP id to bigserial [\#1145](https://github.com/transitland/transitland-datastore/pull/1145) ([irees](https://github.com/irees))
- update gems [\#1143](https://github.com/transitland/transitland-datastore/pull/1143) ([drewda](https://github.com/drewda))
- Production release 72 [\#1128](https://github.com/transitland/transitland-datastore/pull/1128) ([irees](https://github.com/irees))
- Geometry validation & station polygons [\#904](https://github.com/transitland/transitland-datastore/pull/904) ([irees](https://github.com/irees))

## [72](https://github.com/transitland/transitland-datastore/tree/72) (2017-07-20)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/71...72)

**Implemented enhancements:**

- Onestop ID: Include onestop\_id in exception message [\#1052](https://github.com/transitland/transitland-datastore/issues/1052)

**Closed issues:**

- allow uploading of feed versions for an existing feed [\#1125](https://github.com/transitland/transitland-datastore/issues/1125)
- Station hierarchy improvements [\#1066](https://github.com/transitland/transitland-datastore/issues/1066)
- GTFS Station Egress: location\_type = 2 [\#643](https://github.com/transitland/transitland-datastore/issues/643)

**Merged pull requests:**

- Add SSP \(operator\_id, id\) index [\#1139](https://github.com/transitland/transitland-datastore/pull/1139) ([irees](https://github.com/irees))
- updating misc. gems [\#1135](https://github.com/transitland/transitland-datastore/pull/1135) ([drewda](https://github.com/drewda))
- allow uploading of feed versions for an existing feed [\#1134](https://github.com/transitland/transitland-datastore/pull/1134) ([drewda](https://github.com/drewda))
- Improve error message when there is no match on operators\_in\_feed [\#1133](https://github.com/transitland/transitland-datastore/pull/1133) ([irees](https://github.com/irees))
- StopEgress: Load from GTFS [\#1129](https://github.com/transitland/transitland-datastore/pull/1129) ([irees](https://github.com/irees))
- Production release 71 [\#1121](https://github.com/transitland/transitland-datastore/pull/1121) ([irees](https://github.com/irees))

## [71](https://github.com/transitland/transitland-datastore/tree/71) (2017-07-07)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.35...71)

**Closed issues:**

- StopStations: Query param for minimum number of platforms & egresses [\#1124](https://github.com/transitland/transitland-datastore/issues/1124)
- StopStations: Include/exclude generated Platforms & Egresses [\#1123](https://github.com/transitland/transitland-datastore/issues/1123)

**Merged pull requests:**

- StopStations: with\_min\_egresses [\#1127](https://github.com/transitland/transitland-datastore/pull/1127) ([irees](https://github.com/irees))
- Update gtfs gem: Improved CSV handling [\#1126](https://github.com/transitland/transitland-datastore/pull/1126) ([irees](https://github.com/irees))
- StopStationsController: Option to exclude generated platforms and egresses [\#1122](https://github.com/transitland/transitland-datastore/pull/1122) ([irees](https://github.com/irees))
- Production release 4.9.35 [\#1117](https://github.com/transitland/transitland-datastore/pull/1117) ([irees](https://github.com/irees))

## [4.9.35](https://github.com/transitland/transitland-datastore/tree/4.9.35) (2017-06-29)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.34...4.9.35)

**Fixed bugs:**

- Timeout on Issues endpoint [\#1116](https://github.com/transitland/transitland-datastore/issues/1116)

**Merged pull requests:**

- Stop: min platforms query [\#1120](https://github.com/transitland/transitland-datastore/pull/1120) ([irees](https://github.com/irees))
- upgrading to Rails 4.2.9 & updating gems [\#1119](https://github.com/transitland/transitland-datastore/pull/1119) ([drewda](https://github.com/drewda))
- Issue from\_feed query optimization [\#1118](https://github.com/transitland/transitland-datastore/pull/1118) ([irees](https://github.com/irees))
- Remove old GTFSGraph and dependencies [\#1114](https://github.com/transitland/transitland-datastore/pull/1114) ([irees](https://github.com/irees))
- Production release 4.9.34 [\#1113](https://github.com/transitland/transitland-datastore/pull/1113) ([irees](https://github.com/irees))

## [4.9.34](https://github.com/transitland/transitland-datastore/tree/4.9.34) (2017-06-22)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.33...4.9.34)

**Fixed bugs:**

- Stop becomes StopPlatform [\#1103](https://github.com/transitland/transitland-datastore/issues/1103)
- Slow StopsController include query [\#996](https://github.com/transitland/transitland-datastore/issues/996)

**Merged pull requests:**

- Check if Stop is a Stop or StopPlatform [\#1115](https://github.com/transitland/transitland-datastore/pull/1115) ([irees](https://github.com/irees))
- Production release 4.9.33 [\#1110](https://github.com/transitland/transitland-datastore/pull/1110) ([irees](https://github.com/irees))

## [4.9.33](https://github.com/transitland/transitland-datastore/tree/4.9.33) (2017-06-19)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.32...4.9.33)

**Fixed bugs:**

- RSPs missing trips [\#1104](https://github.com/transitland/transitland-datastore/issues/1104)

**Closed issues:**

- Entity Controller Refactor [\#1064](https://github.com/transitland/transitland-datastore/issues/1064)
- Auto-enqueue improvements [\#1038](https://github.com/transitland/transitland-datastore/issues/1038)

**Merged pull requests:**

- CurrentEntityController before\_action fixes [\#1112](https://github.com/transitland/transitland-datastore/pull/1112) ([irees](https://github.com/irees))
- updating mail gem [\#1111](https://github.com/transitland/transitland-datastore/pull/1111) ([drewda](https://github.com/drewda))
- Production release 4.9.32 [\#1102](https://github.com/transitland/transitland-datastore/pull/1102) ([irees](https://github.com/irees))
- CurrentEntityController [\#1096](https://github.com/transitland/transitland-datastore/pull/1096) ([irees](https://github.com/irees))

## [4.9.32](https://github.com/transitland/transitland-datastore/tree/4.9.32) (2017-06-01)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.31...4.9.32)

**Fixed bugs:**

- New GTFS Import: Do not lookup RSPs by EIFF [\#1105](https://github.com/transitland/transitland-datastore/issues/1105)
- SystemStackError: stack level too deep [\#1093](https://github.com/transitland/transitland-datastore/issues/1093)

**Merged pull requests:**

- RSP: Use EIFFs for trips [\#1109](https://github.com/transitland/transitland-datastore/pull/1109) ([irees](https://github.com/irees))
- updating gems & pegging `mail` gem to address security vulnerability [\#1108](https://github.com/transitland/transitland-datastore/pull/1108) ([drewda](https://github.com/drewda))
- RSPs for each Route [\#1106](https://github.com/transitland/transitland-datastore/pull/1106) ([irees](https://github.com/irees))
- Better recursive bounds [\#1101](https://github.com/transitland/transitland-datastore/pull/1101) ([doublestranded](https://github.com/doublestranded))
- FeedVersionInfo: Improved error handling [\#1100](https://github.com/transitland/transitland-datastore/pull/1100) ([irees](https://github.com/irees))
- Production release 4.9.31 [\#1086](https://github.com/transitland/transitland-datastore/pull/1086) ([irees](https://github.com/irees))

## [4.9.31](https://github.com/transitland/transitland-datastore/tree/4.9.31) (2017-05-23)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.30...4.9.31)

**Fixed bugs:**

- only one FeedEater job should run at a time [\#1087](https://github.com/transitland/transitland-datastore/issues/1087)

**Closed issues:**

- FeedVersionInfo filtering: FeedVersion, Feed, and Type [\#1098](https://github.com/transitland/transitland-datastore/issues/1098)
- GTFS Statistics: All filenames [\#1095](https://github.com/transitland/transitland-datastore/issues/1095)
- StopTransfer: Transfers between stations [\#985](https://github.com/transitland/transitland-datastore/issues/985)

**Merged pull requests:**

- FeedVersionInfo: query\_params [\#1099](https://github.com/transitland/transitland-datastore/pull/1099) ([irees](https://github.com/irees))
- Feed version info controller updates [\#1097](https://github.com/transitland/transitland-datastore/pull/1097) ([irees](https://github.com/irees))
- GTFS Statistics: improved filenames [\#1094](https://github.com/transitland/transitland-datastore/pull/1094) ([irees](https://github.com/irees))
- update mail gem [\#1092](https://github.com/transitland/transitland-datastore/pull/1092) ([drewda](https://github.com/drewda))
- updating gems, including Sidekiq and Redis libraries [\#1090](https://github.com/transitland/transitland-datastore/pull/1090) ([drewda](https://github.com/drewda))
- Production release 4.9.30-2   [\#1089](https://github.com/transitland/transitland-datastore/pull/1089) ([drewda](https://github.com/drewda))
- only one FeedEater job should run at a time [\#1088](https://github.com/transitland/transitland-datastore/pull/1088) ([drewda](https://github.com/drewda))
- Production release 4.9.30 [\#1080](https://github.com/transitland/transitland-datastore/pull/1080) ([irees](https://github.com/irees))
- GTFS Graph Refactor [\#1037](https://github.com/transitland/transitland-datastore/pull/1037) ([irees](https://github.com/irees))

## [4.9.30](https://github.com/transitland/transitland-datastore/tree/4.9.30) (2017-05-09)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.29...4.9.30)

**Fixed bugs:**

- NoMethodError: undefined method `valid\_password?' for nil:NilClass [\#1082](https://github.com/transitland/transitland-datastore/issues/1082)

**Closed issues:**

- Sidekiq: high & low priority queues [\#1078](https://github.com/transitland/transitland-datastore/issues/1078)

**Merged pull requests:**

- Limit low priority queue to 1 thread per process [\#1084](https://github.com/transitland/transitland-datastore/pull/1084) ([irees](https://github.com/irees))
- when creating a session, make sure that user is found [\#1083](https://github.com/transitland/transitland-datastore/pull/1083) ([drewda](https://github.com/drewda))
- Workers: use GTFS\_TMPDIR\_BASEPATH [\#1081](https://github.com/transitland/transitland-datastore/pull/1081) ([irees](https://github.com/irees))
- Dist calc recursion [\#1077](https://github.com/transitland/transitland-datastore/pull/1077) ([doublestranded](https://github.com/doublestranded))
- Production release 4.9.29 [\#1075](https://github.com/transitland/transitland-datastore/pull/1075) ([irees](https://github.com/irees))

## [4.9.29](https://github.com/transitland/transitland-datastore/tree/4.9.29) (2017-05-03)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.28...4.9.29)

**Merged pull requests:**

- Sidekiq queue adjustments [\#1079](https://github.com/transitland/transitland-datastore/pull/1079) ([irees](https://github.com/irees))
- Production release 4.9.28 [\#1065](https://github.com/transitland/transitland-datastore/pull/1065) ([irees](https://github.com/irees))

## [4.9.28](https://github.com/transitland/transitland-datastore/tree/4.9.28) (2017-04-28)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.27...4.9.28)

**Closed issues:**

- StopEgress directionality [\#1072](https://github.com/transitland/transitland-datastore/issues/1072)
- API not returning objects when requested by gtfs\_id [\#1070](https://github.com/transitland/transitland-datastore/issues/1070)
- feedvalidator.py: ensure tmp sqlite db files are removed [\#1069](https://github.com/transitland/transitland-datastore/issues/1069)
- Missing allowed query\_params in pagination [\#1062](https://github.com/transitland/transitland-datastore/issues/1062)
- Show feedvalidator.py results in IFrame [\#1061](https://github.com/transitland/transitland-datastore/issues/1061)
- run external validator libraries on new feed versions [\#888](https://github.com/transitland/transitland-datastore/issues/888)

**Merged pull requests:**

- Run validators in tmpdir [\#1074](https://github.com/transitland/transitland-datastore/pull/1074) ([irees](https://github.com/irees))
- Allow either imported\_with\_gtfs\_id or gtfs\_id [\#1071](https://github.com/transitland/transitland-datastore/pull/1071) ([irees](https://github.com/irees))
- StopEgress directionality [\#1068](https://github.com/transitland/transitland-datastore/pull/1068) ([irees](https://github.com/irees))
- StopPlatform: mark as generated [\#1067](https://github.com/transitland/transitland-datastore/pull/1067) ([irees](https://github.com/irees))
- Production release 4.9.27 [\#1053](https://github.com/transitland/transitland-datastore/pull/1053) ([irees](https://github.com/irees))

## [4.9.27](https://github.com/transitland/transitland-datastore/tree/4.9.27) (2017-04-15)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.26...4.9.27)

**Implemented enhancements:**

- Improve first and last stop distance logic [\#1047](https://github.com/transitland/transitland-datastore/issues/1047)

**Fixed bugs:**

- Distance calc using shape\_dist\_traveled within segment ratio bug [\#1045](https://github.com/transitland/transitland-datastore/issues/1045)
- Distance calc matching too early sometimes [\#1043](https://github.com/transitland/transitland-datastore/issues/1043)

**Closed issues:**

- Validation of shape\_dist\_traveled [\#1057](https://github.com/transitland/transitland-datastore/issues/1057)
- update Google TransitFeed validator dependency [\#1054](https://github.com/transitland/transitland-datastore/issues/1054)
- FeedVersion update sometimes removes cached file [\#1049](https://github.com/transitland/transitland-datastore/issues/1049)
- allow Users to authenticate against API using JSON Web Tokens [\#623](https://github.com/transitland/transitland-datastore/issues/623)

**Merged pull requests:**

- Update allowed query\_params [\#1063](https://github.com/transitland/transitland-datastore/pull/1063) ([irees](https://github.com/irees))
- Feed version serializer: include feed [\#1060](https://github.com/transitland/transitland-datastore/pull/1060) ([irees](https://github.com/irees))
- Validate gtfs shape dist traveled [\#1058](https://github.com/transitland/transitland-datastore/pull/1058) ([doublestranded](https://github.com/doublestranded))
- update gems [\#1056](https://github.com/transitland/transitland-datastore/pull/1056) ([drewda](https://github.com/drewda))
- updating Google Python-based validator library [\#1055](https://github.com/transitland/transitland-datastore/pull/1055) ([drewda](https://github.com/drewda))
- Feed version info serializer updates [\#1051](https://github.com/transitland/transitland-datastore/pull/1051) ([irees](https://github.com/irees))
- FeedVersion update sometimes removes cached file [\#1050](https://github.com/transitland/transitland-datastore/pull/1050) ([irees](https://github.com/irees))
- First stop seg matching improvement [\#1048](https://github.com/transitland/transitland-datastore/pull/1048) ([doublestranded](https://github.com/doublestranded))
- Seg ratio fix [\#1046](https://github.com/transitland/transitland-datastore/pull/1046) ([doublestranded](https://github.com/doublestranded))
- Production release 4.9.26 [\#1035](https://github.com/transitland/transitland-datastore/pull/1035) ([irees](https://github.com/irees))
- Conveyal gtfs-lib validation [\#1029](https://github.com/transitland/transitland-datastore/pull/1029) ([irees](https://github.com/irees))
- User authentication using JWT [\#624](https://github.com/transitland/transitland-datastore/pull/624) ([drewda](https://github.com/drewda))

## [4.9.26](https://github.com/transitland/transitland-datastore/tree/4.9.26) (2017-03-31)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.25...4.9.26)

**Implemented enhancements:**

- FeedVersion: import\_status [\#1040](https://github.com/transitland/transitland-datastore/issues/1040)
- RSP distances inaccurate in complex loops [\#1033](https://github.com/transitland/transitland-datastore/issues/1033)
- Refactor Distance Calculation and geometry methods into service [\#1032](https://github.com/transitland/transitland-datastore/issues/1032)

**Fixed bugs:**

- RSP distances inaccurate in complex loops [\#1033](https://github.com/transitland/transitland-datastore/issues/1033)
- Distance calc using shape\_dist\_traveled within segment problem [\#1028](https://github.com/transitland/transitland-datastore/issues/1028)

**Merged pull requests:**

- Before stop first only [\#1044](https://github.com/transitland/transitland-datastore/pull/1044) ([doublestranded](https://github.com/doublestranded))
- upgrade gems [\#1042](https://github.com/transitland/transitland-datastore/pull/1042) ([drewda](https://github.com/drewda))
- FeedVersion import\_status [\#1041](https://github.com/transitland/transitland-datastore/pull/1041) ([irees](https://github.com/irees))
- Shape dist traveled within seg fix [\#1039](https://github.com/transitland/transitland-datastore/pull/1039) ([doublestranded](https://github.com/doublestranded))
- FeedVersion Serializer: Include FeedVersionInfo IDs [\#1036](https://github.com/transitland/transitland-datastore/pull/1036) ([irees](https://github.com/irees))
- Distance calculation refactor [\#1034](https://github.com/transitland/transitland-datastore/pull/1034) ([doublestranded](https://github.com/doublestranded))
- Production release 4.9.25 [\#1013](https://github.com/transitland/transitland-datastore/pull/1013) ([irees](https://github.com/irees))

## [4.9.25](https://github.com/transitland/transitland-datastore/tree/4.9.25) (2017-03-24)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.24...4.9.25)

**Fixed bugs:**

- RSP geometry source string-sym comparison mismatch [\#1024](https://github.com/transitland/transitland-datastore/issues/1024)
- Feeds: urlencode nested-zip URI fragments [\#1022](https://github.com/transitland/transitland-datastore/issues/1022)
- RouteStopPattern gtfs\_shape\_dist\_traveled: seg\_index is nil [\#1020](https://github.com/transitland/transitland-datastore/issues/1020)

**Closed issues:**

- when logging exceptions to Sentry, include context [\#1018](https://github.com/transitland/transitland-datastore/issues/1018)
- feeds API endpoint: allow filtering by URL [\#1010](https://github.com/transitland/transitland-datastore/issues/1010)
- Feed Validation Worker [\#1009](https://github.com/transitland/transitland-datastore/issues/1009)
- schedule\_stop\_pairs: time=now [\#1008](https://github.com/transitland/transitland-datastore/issues/1008)
- schedule\_stop\_pairs: date=today query param [\#965](https://github.com/transitland/transitland-datastore/issues/965)
- FeedVersion descriptive stats [\#646](https://github.com/transitland/transitland-datastore/issues/646)
- upgrade Carrierwave gem now that it has been released [\#639](https://github.com/transitland/transitland-datastore/issues/639)
- Frequency-based trips [\#408](https://github.com/transitland/transitland-datastore/issues/408)

**Merged pull requests:**

- Fix bug when a calendar entry has no trips associated [\#1031](https://github.com/transitland/transitland-datastore/pull/1031) ([irees](https://github.com/irees))
- Shape dist traveled nil fix [\#1027](https://github.com/transitland/transitland-datastore/pull/1027) ([doublestranded](https://github.com/doublestranded))
- Update GTFS to fix urlencoding issue [\#1026](https://github.com/transitland/transitland-datastore/pull/1026) ([irees](https://github.com/irees))
- Geometry source comparison fix [\#1025](https://github.com/transitland/transitland-datastore/pull/1025) ([doublestranded](https://github.com/doublestranded))
- Feed Statistics [\#1021](https://github.com/transitland/transitland-datastore/pull/1021) ([irees](https://github.com/irees))
- when logging exceptions to Sentry, include context [\#1019](https://github.com/transitland/transitland-datastore/pull/1019) ([drewda](https://github.com/drewda))
- Upgrade to Rails 4.2.8 and update gems [\#1016](https://github.com/transitland/transitland-datastore/pull/1016) ([drewda](https://github.com/drewda))
- feeds API endpoint: allow filtering by URL [\#1015](https://github.com/transitland/transitland-datastore/pull/1015) ([drewda](https://github.com/drewda))
- Minor FeedValidationService updates [\#1014](https://github.com/transitland/transitland-datastore/pull/1014) ([irees](https://github.com/irees))
- FeedValidationWorker [\#1012](https://github.com/transitland/transitland-datastore/pull/1012) ([irees](https://github.com/irees))
- removing identifiers [\#1011](https://github.com/transitland/transitland-datastore/pull/1011) ([drewda](https://github.com/drewda))
- Update gems [\#1007](https://github.com/transitland/transitland-datastore/pull/1007) ([drewda](https://github.com/drewda))
- Production release 4.9.24 [\#1005](https://github.com/transitland/transitland-datastore/pull/1005) ([irees](https://github.com/irees))

## [4.9.24](https://github.com/transitland/transitland-datastore/tree/4.9.24) (2017-03-07)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.23...4.9.24)

**Implemented enhancements:**

- Utilize stop\_times.txt and shapes.txt shape\_dist\_traveled [\#987](https://github.com/transitland/transitland-datastore/issues/987)
- Route endpoint: Accept multiple operated\_by operators [\#710](https://github.com/transitland/transitland-datastore/issues/710)

**Fixed bugs:**

- Non-import changesets should update nil stop distances of SSPs [\#1002](https://github.com/transitland/transitland-datastore/issues/1002)

**Closed issues:**

- Optimize SSP distances in update computed attributes [\#1000](https://github.com/transitland/transitland-datastore/issues/1000)
- Validate entity attribute on EntityWithIssues model [\#998](https://github.com/transitland/transitland-datastore/issues/998)
- Quality Issue for RSP reversed geometry [\#925](https://github.com/transitland/transitland-datastore/issues/925)
- refactor computed properties [\#829](https://github.com/transitland/transitland-datastore/issues/829)
- Changeset: entity destroy is order dependent [\#742](https://github.com/transitland/transitland-datastore/issues/742)
- FeedEater creates Changeset that only represent entity diffs [\#571](https://github.com/transitland/transitland-datastore/issues/571)
- Stop EIFF Debugging [\#561](https://github.com/transitland/transitland-datastore/issues/561)
- Error parsing GTFS CSV with incorrect quote escaping [\#511](https://github.com/transitland/transitland-datastore/issues/511)
- store Who's on First integer IDs for Feed country and region \(in addition to string names\) [\#284](https://github.com/transitland/transitland-datastore/issues/284)

**Merged pull requests:**

- operator name look-up needs to properly handle case insensitive queries of UTF-8 strings [\#1004](https://github.com/transitland/transitland-datastore/pull/1004) ([drewda](https://github.com/drewda))
- updating ssp distances for non-import changesets [\#1003](https://github.com/transitland/transitland-datastore/pull/1003) ([doublestranded](https://github.com/doublestranded))
- Update computed attributes refactor [\#995](https://github.com/transitland/transitland-datastore/pull/995) ([doublestranded](https://github.com/doublestranded))
- Utilize shape dist traveled [\#994](https://github.com/transitland/transitland-datastore/pull/994) ([doublestranded](https://github.com/doublestranded))
- SSPs: date=today [\#989](https://github.com/transitland/transitland-datastore/pull/989) ([irees](https://github.com/irees))
- Production release 4.9.23 [\#976](https://github.com/transitland/transitland-datastore/pull/976) ([irees](https://github.com/irees))
- Switch to iso 3166 [\#955](https://github.com/transitland/transitland-datastore/pull/955) ([drewda](https://github.com/drewda))

## [4.9.23](https://github.com/transitland/transitland-datastore/tree/4.9.23) (2017-03-01)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.22...4.9.23)

**Implemented enhancements:**

- rsp\_line\_inaccurate quality check fix [\#771](https://github.com/transitland/transitland-datastore/issues/771)
- RSP Optimization 2 [\#748](https://github.com/transitland/transitland-datastore/issues/748)

**Fixed bugs:**

- Bounds not including rsp\_line\_inaccurate RSPs [\#991](https://github.com/transitland/transitland-datastore/issues/991)
- FeedVersion: Duplicate sha1 [\#981](https://github.com/transitland/transitland-datastore/issues/981)
- createUpdate looks back at old merged and changed records [\#963](https://github.com/transitland/transitland-datastore/issues/963)
- rsp\\_line\\_inaccurate quality check fix [\#771](https://github.com/transitland/transitland-datastore/issues/771)

**Closed issues:**

- Create Issue when a Feed import has no matching Operators [\#997](https://github.com/transitland/transitland-datastore/issues/997)
- Still more "false positive" issues with dist calc [\#945](https://github.com/transitland/transitland-datastore/issues/945)
- Remove rake task for deleting unreferenced entities [\#926](https://github.com/transitland/transitland-datastore/issues/926)
- Hide or delete 'inactive' RouteStopPatterns [\#907](https://github.com/transitland/transitland-datastore/issues/907)

**Merged pull requests:**

- Entity attribute validate [\#999](https://github.com/transitland/transitland-datastore/pull/999) ([doublestranded](https://github.com/doublestranded))
- Issue: Feed import with no matching operators [\#993](https://github.com/transitland/transitland-datastore/pull/993) ([irees](https://github.com/irees))
- False positive stops close issues [\#990](https://github.com/transitland/transitland-datastore/pull/990) ([doublestranded](https://github.com/doublestranded))
- Guard against cycles [\#988](https://github.com/transitland/transitland-datastore/pull/988) ([irees](https://github.com/irees))
- Import: better traverse stops, stations, transfers [\#986](https://github.com/transitland/transitland-datastore/pull/986) ([irees](https://github.com/irees))
- RSP: Improved create\_from\_gtfs [\#984](https://github.com/transitland/transitland-datastore/pull/984) ([irees](https://github.com/irees))
- Optimize memory before after stops [\#983](https://github.com/transitland/transitland-datastore/pull/983) ([doublestranded](https://github.com/doublestranded))
- Create FeedVersion before uploading attachments [\#982](https://github.com/transitland/transitland-datastore/pull/982) ([irees](https://github.com/irees))
- Rsp line inaccurate fix [\#980](https://github.com/transitland/transitland-datastore/pull/980) ([doublestranded](https://github.com/doublestranded))
- Remove rake task for unreferenced entities [\#979](https://github.com/transitland/transitland-datastore/pull/979) ([doublestranded](https://github.com/doublestranded))
- double-quoted string [\#978](https://github.com/transitland/transitland-datastore/pull/978) ([doublestranded](https://github.com/doublestranded))
- Remove old rsps [\#977](https://github.com/transitland/transitland-datastore/pull/977) ([doublestranded](https://github.com/doublestranded))
- Production release 4.9.22 [\#953](https://github.com/transitland/transitland-datastore/pull/953) ([irees](https://github.com/irees))

## [4.9.22](https://github.com/transitland/transitland-datastore/tree/4.9.22) (2017-02-17)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.21...4.9.22)

**Fixed bugs:**

- Query of RouteStopPatterns by any stops wrong [\#968](https://github.com/transitland/transitland-datastore/issues/968)
- Berlin import error in operators [\#930](https://github.com/transitland/transitland-datastore/issues/930)

**Closed issues:**

- Frequency adjustments for interpolated stop\_times [\#973](https://github.com/transitland/transitland-datastore/issues/973)
- Missing transfer Stops [\#972](https://github.com/transitland/transitland-datastore/issues/972)
- Direct relationship between parent stations and stops/platforms? [\#971](https://github.com/transitland/transitland-datastore/issues/971)
- Frequency import: interpolated schedules [\#961](https://github.com/transitland/transitland-datastore/issues/961)
- gtfs\_graph\_spec quite slow [\#958](https://github.com/transitland/transitland-datastore/issues/958)
- Frequency based schedules: relative arrival/destination times in SSPs [\#951](https://github.com/transitland/transitland-datastore/issues/951)
- Change exclude\_geometry false default to include\_geometry true [\#939](https://github.com/transitland/transitland-datastore/issues/939)
- Optional embedding of issues [\#913](https://github.com/transitland/transitland-datastore/issues/913)
- Remove Feed onestop\_id from s3 filenames [\#895](https://github.com/transitland/transitland-datastore/issues/895)
- Issues can be falsely "resolved" on changeset [\#701](https://github.com/transitland/transitland-datastore/issues/701)
- add Javadoc-style inline docs to GtfsGraph [\#399](https://github.com/transitland/transitland-datastore/issues/399)
- Onestop ID lineage/deaccessioning [\#332](https://github.com/transitland/transitland-datastore/issues/332)
- remove EntityImportedFromFeed join model [\#276](https://github.com/transitland/transitland-datastore/issues/276)

**Merged pull requests:**

- stops endpoint: when a stop has a parent, include its Onestop ID [\#975](https://github.com/transitland/transitland-datastore/pull/975) ([drewda](https://github.com/drewda))
- Missing transfer Stops [\#970](https://github.com/transitland/transitland-datastore/pull/970) ([irees](https://github.com/irees))
- Update computed attrs bug fix [\#969](https://github.com/transitland/transitland-datastore/pull/969) ([doublestranded](https://github.com/doublestranded))
- Guard against missing arrival/departure times [\#967](https://github.com/transitland/transitland-datastore/pull/967) ([irees](https://github.com/irees))
- Guard against nil geometry returned by convex\_hull [\#966](https://github.com/transitland/transitland-datastore/pull/966) ([irees](https://github.com/irees))
- createUpdate now looks back for merged and changed records [\#964](https://github.com/transitland/transitland-datastore/pull/964) ([doublestranded](https://github.com/doublestranded))
- removing CodeCov integration [\#962](https://github.com/transitland/transitland-datastore/pull/962) ([drewda](https://github.com/drewda))
- Don't use Feed OnestopIDs in S3 filenames [\#960](https://github.com/transitland/transitland-datastore/pull/960) ([irees](https://github.com/irees))
- Run specs even faster [\#959](https://github.com/transitland/transitland-datastore/pull/959) ([irees](https://github.com/irees))
- Embedded entity issues [\#957](https://github.com/transitland/transitland-datastore/pull/957) ([doublestranded](https://github.com/doublestranded))
- Faster GTFS import specs [\#956](https://github.com/transitland/transitland-datastore/pull/956) ([irees](https://github.com/irees))
- Service clean up [\#954](https://github.com/transitland/transitland-datastore/pull/954) ([drewda](https://github.com/drewda))
- Frequency trips: arrival/departure times relative to start of trip [\#952](https://github.com/transitland/transitland-datastore/pull/952) ([irees](https://github.com/irees))
- updating gems [\#950](https://github.com/transitland/transitland-datastore/pull/950) ([drewda](https://github.com/drewda))
- Production release 4.9.21 [\#938](https://github.com/transitland/transitland-datastore/pull/938) ([irees](https://github.com/irees))
- Onestop id lineage [\#910](https://github.com/transitland/transitland-datastore/pull/910) ([doublestranded](https://github.com/doublestranded))
- unresolved issues from non-matching entities [\#871](https://github.com/transitland/transitland-datastore/pull/871) ([doublestranded](https://github.com/doublestranded))

## [4.9.21](https://github.com/transitland/transitland-datastore/tree/4.9.21) (2017-02-06)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.20...4.9.21)

**Implemented enhancements:**

- Add "stale" enum attribute to Issue model [\#747](https://github.com/transitland/transitland-datastore/issues/747)
- Automatic issue resolution on manual changeset [\#746](https://github.com/transitland/transitland-datastore/issues/746)
- Incorporate shape\_dist\_traveled if available [\#585](https://github.com/transitland/transitland-datastore/issues/585)
- Integrate RSP distance interpolation with SSP interpolation methods [\#565](https://github.com/transitland/transitland-datastore/issues/565)

**Fixed bugs:**

- Couldn't find stops in quality checks [\#941](https://github.com/transitland/transitland-datastore/issues/941)
- Route without RSPS [\#842](https://github.com/transitland/transitland-datastore/issues/842)

**Closed issues:**

- Endpoint that redirects to download the latest version of a feed [\#947](https://github.com/transitland/transitland-datastore/issues/947)
- Harmonize common query parameters across onestop\_id entity controllers [\#943](https://github.com/transitland/transitland-datastore/issues/943)
- Find entities based on GTFS ID [\#942](https://github.com/transitland/transitland-datastore/issues/942)
- Quality issue for RSP wrong trip [\#937](https://github.com/transitland/transitland-datastore/issues/937)
- Manually close "false positive issues" [\#935](https://github.com/transitland/transitland-datastore/issues/935)
- Enable StopTransfers [\#903](https://github.com/transitland/transitland-datastore/issues/903)
- Add Representative Route method to docs [\#848](https://github.com/transitland/transitland-datastore/issues/848)
- try CodeCov.io for test coverage reports [\#676](https://github.com/transitland/transitland-datastore/issues/676)
- Changeset references across multiple ChangePayloads [\#667](https://github.com/transitland/transitland-datastore/issues/667)
- Animation for distance calc algorithm in docs [\#633](https://github.com/transitland/transitland-datastore/issues/633)

**Merged pull requests:**

- Update gtfs gem [\#949](https://github.com/transitland/transitland-datastore/pull/949) ([irees](https://github.com/irees))
- endpoint that redirects to download the latest version of a feed [\#948](https://github.com/transitland/transitland-datastore/pull/948) ([drewda](https://github.com/drewda))
- gtfs gem update: support ftp & additional feed/agency contact details. [\#946](https://github.com/transitland/transitland-datastore/pull/946) ([irees](https://github.com/irees))
- Include geometry [\#944](https://github.com/transitland/transitland-datastore/pull/944) ([doublestranded](https://github.com/doublestranded))
- Find by gtfs\_id [\#940](https://github.com/transitland/transitland-datastore/pull/940) ([irees](https://github.com/irees))
- Production release 4.9.20 [\#934](https://github.com/transitland/transitland-datastore/pull/934) ([irees](https://github.com/irees))
- Improved handling of Changeset associations [\#928](https://github.com/transitland/transitland-datastore/pull/928) ([irees](https://github.com/irees))
- Enable StopTransfers [\#924](https://github.com/transitland/transitland-datastore/pull/924) ([irees](https://github.com/irees))
- try CodeCov.io for test coverage reports [\#677](https://github.com/transitland/transitland-datastore/pull/677) ([drewda](https://github.com/drewda))

## [4.9.20](https://github.com/transitland/transitland-datastore/tree/4.9.20) (2017-01-25)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.19...4.9.20)

**Closed issues:**

- Exclude Route Geometry in API [\#866](https://github.com/transitland/transitland-datastore/issues/866)

**Merged pull requests:**

- Fix missing Stations [\#936](https://github.com/transitland/transitland-datastore/pull/936) ([irees](https://github.com/irees))
- Production release 4.9.19 [\#927](https://github.com/transitland/transitland-datastore/pull/927) ([doublestranded](https://github.com/doublestranded))

## [4.9.19](https://github.com/transitland/transitland-datastore/tree/4.9.19) (2017-01-23)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.18...4.9.19)

**Fixed bugs:**

- Import failure on RSP onestop\_id [\#918](https://github.com/transitland/transitland-datastore/issues/918)

**Closed issues:**

- Stations missing EIFFs [\#931](https://github.com/transitland/transitland-datastore/issues/931)
- Set RSP distances to null if errors [\#929](https://github.com/transitland/transitland-datastore/issues/929)

**Merged pull requests:**

- Stop distances nil fallback [\#933](https://github.com/transitland/transitland-datastore/pull/933) ([doublestranded](https://github.com/doublestranded))
- Fix Stations missing EIFFs [\#932](https://github.com/transitland/transitland-datastore/pull/932) ([irees](https://github.com/irees))
- \[WIP\] Production release 4.9.18 [\#922](https://github.com/transitland/transitland-datastore/pull/922) ([doublestranded](https://github.com/doublestranded))
- Optional geometry [\#915](https://github.com/transitland/transitland-datastore/pull/915) ([doublestranded](https://github.com/doublestranded))
- Identifier matching in GTFSGraph [\#894](https://github.com/transitland/transitland-datastore/pull/894) ([irees](https://github.com/irees))

## [4.9.18](https://github.com/transitland/transitland-datastore/tree/4.9.18) (2017-01-12)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.17...4.9.18)

**Fixed bugs:**

- sfmta route 23 distance calc issue [\#538](https://github.com/transitland/transitland-datastore/issues/538)

**Closed issues:**

- Maintenance task to remove Feed and all entities [\#919](https://github.com/transitland/transitland-datastore/issues/919)

**Merged pull requests:**

- ignoring nil routes [\#923](https://github.com/transitland/transitland-datastore/pull/923) ([doublestranded](https://github.com/doublestranded))
- Feed Maintenance: destroy feed [\#920](https://github.com/transitland/transitland-datastore/pull/920) ([irees](https://github.com/irees))
- Production release 4.9.17 [\#902](https://github.com/transitland/transitland-datastore/pull/902) ([irees](https://github.com/irees))
- Dist calc index update [\#849](https://github.com/transitland/transitland-datastore/pull/849) ([doublestranded](https://github.com/doublestranded))

## [4.9.17](https://github.com/transitland/transitland-datastore/tree/4.9.17) (2017-01-10)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.16...4.9.17)

**Fixed bugs:**

- Avoid Station Hierarchy issues duplication [\#908](https://github.com/transitland/transitland-datastore/issues/908)
- FeedFetchService: Handle feedvalidator.py exceptions [\#900](https://github.com/transitland/transitland-datastore/issues/900)

**Closed issues:**

- Allow multiple operator ids in routes "operated\_by" query [\#914](https://github.com/transitland/transitland-datastore/issues/914)
- Stop Station Issue serialization [\#911](https://github.com/transitland/transitland-datastore/issues/911)
- Remove or reduce "false positive" issues [\#846](https://github.com/transitland/transitland-datastore/issues/846)

**Merged pull requests:**

- convert embed\_issues param value to boolean [\#921](https://github.com/transitland/transitland-datastore/pull/921) ([doublestranded](https://github.com/doublestranded))
- Ignoring stops that are repeated [\#917](https://github.com/transitland/transitland-datastore/pull/917) ([doublestranded](https://github.com/doublestranded))
- operated\_by query allows multiple operators [\#916](https://github.com/transitland/transitland-datastore/pull/916) ([doublestranded](https://github.com/doublestranded))
- Issues with stop stations [\#912](https://github.com/transitland/transitland-datastore/pull/912) ([doublestranded](https://github.com/doublestranded))
- fixed details bug and avoiding duplication [\#909](https://github.com/transitland/transitland-datastore/pull/909) ([doublestranded](https://github.com/doublestranded))
- Production release 4.9.16 [\#889](https://github.com/transitland/transitland-datastore/pull/889) ([irees](https://github.com/irees))
- Remove duplicate point same distance issues [\#847](https://github.com/transitland/transitland-datastore/pull/847) ([doublestranded](https://github.com/doublestranded))

## [4.9.16](https://github.com/transitland/transitland-datastore/tree/4.9.16) (2016-12-20)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.14...4.9.16)

**Implemented enhancements:**

- Updates to Issues/EWIs serializers [\#878](https://github.com/transitland/transitland-datastore/issues/878)

**Fixed bugs:**

- Finnish feed "f-u6x-turunlinja~autoilijainosakeyhtiö~savonlinjaoy~sl~autolinja" won't import [\#881](https://github.com/transitland/transitland-datastore/issues/881)

**Closed issues:**

- Issue category endpoint [\#898](https://github.com/transitland/transitland-datastore/issues/898)
- Sidekiq Monitoring authentication [\#897](https://github.com/transitland/transitland-datastore/issues/897)
- Gentle failure on bad stop\_times.txt data [\#892](https://github.com/transitland/transitland-datastore/issues/892)
- Use global log method [\#886](https://github.com/transitland/transitland-datastore/issues/886)
- OIF: Allow null gtfs\_agency\_id [\#884](https://github.com/transitland/transitland-datastore/issues/884)
- EntityWithIssues serialize id [\#876](https://github.com/transitland/transitland-datastore/issues/876)
- Station Hierarchy Quality Checks [\#869](https://github.com/transitland/transitland-datastore/issues/869)
- FeedEater: Lookup entities by identifier [\#669](https://github.com/transitland/transitland-datastore/issues/669)

**Merged pull requests:**

- Feedvalidator ops improvements [\#901](https://github.com/transitland/transitland-datastore/pull/901) ([irees](https://github.com/irees))
- Issue categories controller [\#899](https://github.com/transitland/transitland-datastore/pull/899) ([doublestranded](https://github.com/doublestranded))
- Fix Sidekiq Monitoring authentication [\#896](https://github.com/transitland/transitland-datastore/pull/896) ([irees](https://github.com/irees))
- Station hierarchy issues [\#893](https://github.com/transitland/transitland-datastore/pull/893) ([doublestranded](https://github.com/doublestranded))
- Gentle failure on bad stop\_times [\#891](https://github.com/transitland/transitland-datastore/pull/891) ([irees](https://github.com/irees))
- StopStationsController serializer update [\#890](https://github.com/transitland/transitland-datastore/pull/890) ([irees](https://github.com/irees))
- Update gtfs gem [\#887](https://github.com/transitland/transitland-datastore/pull/887) ([irees](https://github.com/irees))
- Use global log method [\#885](https://github.com/transitland/transitland-datastore/pull/885) ([irees](https://github.com/irees))
- OIF: Allow null gtfs\_agency\_id [\#883](https://github.com/transitland/transitland-datastore/pull/883) ([irees](https://github.com/irees))
- handling case where all shape points equal [\#882](https://github.com/transitland/transitland-datastore/pull/882) ([doublestranded](https://github.com/doublestranded))
- Roll back redis gems [\#880](https://github.com/transitland/transitland-datastore/pull/880) ([irees](https://github.com/irees))
- Issue serialization update [\#879](https://github.com/transitland/transitland-datastore/pull/879) ([doublestranded](https://github.com/doublestranded))
- Entity with issues serialize [\#877](https://github.com/transitland/transitland-datastore/pull/877) ([doublestranded](https://github.com/doublestranded))
- Production release 4.9.15 [\#875](https://github.com/transitland/transitland-datastore/pull/875) ([irees](https://github.com/irees))
- Production release 4.9.14 [\#863](https://github.com/transitland/transitland-datastore/pull/863) ([irees](https://github.com/irees))
- EIFF: Include GTFS identifier [\#854](https://github.com/transitland/transitland-datastore/pull/854) ([irees](https://github.com/irees))

## [4.9.14](https://github.com/transitland/transitland-datastore/tree/4.9.14) (2016-12-07)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.13...4.9.14)

**Implemented enhancements:**

- Feed issues association [\#864](https://github.com/transitland/transitland-datastore/issues/864)
- allow filtering of feed versions by calendar dates [\#851](https://github.com/transitland/transitland-datastore/issues/851)

**Closed issues:**

- FeedVersion: Attach feedvalidator.py output [\#868](https://github.com/transitland/transitland-datastore/issues/868)
- Sample Changeset Feeds need geometries [\#859](https://github.com/transitland/transitland-datastore/issues/859)
- Issue for null island stops [\#835](https://github.com/transitland/transitland-datastore/issues/835)
- OperatorsInFeed: Operator referenced by multiple gtfs agency\_id's [\#735](https://github.com/transitland/transitland-datastore/issues/735)

**Merged pull requests:**

- FeedVersion serializer: url [\#874](https://github.com/transitland/transitland-datastore/pull/874) ([irees](https://github.com/irees))
- Feedvalidator attachment fixes [\#873](https://github.com/transitland/transitland-datastore/pull/873) ([irees](https://github.com/irees))
- FeedVersion: Attach feedvalidator.py output [\#872](https://github.com/transitland/transitland-datastore/pull/872) ([irees](https://github.com/irees))
- update gems [\#870](https://github.com/transitland/transitland-datastore/pull/870) ([drewda](https://github.com/drewda))
- FeedVersion: filter calendar dates [\#867](https://github.com/transitland/transitland-datastore/pull/867) ([irees](https://github.com/irees))
- feed issue associations and serialization [\#865](https://github.com/transitland/transitland-datastore/pull/865) ([doublestranded](https://github.com/doublestranded))
- copying operator geoms over to feed [\#860](https://github.com/transitland/transitland-datastore/pull/860) ([doublestranded](https://github.com/doublestranded))
- Production release 4.9.13 [\#858](https://github.com/transitland/transitland-datastore/pull/858) ([irees](https://github.com/irees))
- Null island stop issues [\#845](https://github.com/transitland/transitland-datastore/pull/845) ([doublestranded](https://github.com/doublestranded))
- Feed: Operator referenced by multiple gtfs agency\_id's [\#743](https://github.com/transitland/transitland-datastore/pull/743) ([irees](https://github.com/irees))

## [4.9.13](https://github.com/transitland/transitland-datastore/tree/4.9.13) (2016-11-21)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.12...4.9.13)

**Implemented enhancements:**

- When bulk deactivating issues, make sure it's done asynchronously [\#787](https://github.com/transitland/transitland-datastore/issues/787)

**Closed issues:**

- Override stops controller to use 'stops' as root [\#862](https://github.com/transitland/transitland-datastore/issues/862)
- Save Feed fetch errors as issues [\#820](https://github.com/transitland/transitland-datastore/issues/820)

**Merged pull requests:**

- Stop serializer root fix [\#861](https://github.com/transitland/transitland-datastore/pull/861) ([irees](https://github.com/irees))
- feed fetch errors create issues [\#844](https://github.com/transitland/transitland-datastore/pull/844) ([doublestranded](https://github.com/doublestranded))
- Production release 4.9.12 [\#843](https://github.com/transitland/transitland-datastore/pull/843) ([irees](https://github.com/irees))

## [4.9.12](https://github.com/transitland/transitland-datastore/tree/4.9.12) (2016-11-14)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.11...4.9.12)

**Implemented enhancements:**

- Issues deprecated by Changeset Entity [\#816](https://github.com/transitland/transitland-datastore/issues/816)

**Fixed bugs:**

- NoMethodError: undefined method `match' for \#\<Array:0x007f6712bd9888\> [\#850](https://github.com/transitland/transitland-datastore/issues/850)
- Import: "Undefined method 'factory'" [\#831](https://github.com/transitland/transitland-datastore/issues/831)
- GeoJSON nested serializers [\#616](https://github.com/transitland/transitland-datastore/issues/616)

**Closed issues:**

- Geometry validation [\#855](https://github.com/transitland/transitland-datastore/issues/855)
- use Onestop IDs as primary and foreign keys \(to reduce needs for cross-table joins\) [\#278](https://github.com/transitland/transitland-datastore/issues/278)

**Merged pull requests:**

- Geometry required [\#857](https://github.com/transitland/transitland-datastore/pull/857) ([irees](https://github.com/irees))
- Fix jsonapi gem [\#856](https://github.com/transitland/transitland-datastore/pull/856) ([irees](https://github.com/irees))
- Convert logging message to string [\#853](https://github.com/transitland/transitland-datastore/pull/853) ([irees](https://github.com/irees))
- Fix for loading gtfs frequencies [\#852](https://github.com/transitland/transitland-datastore/pull/852) ([irees](https://github.com/irees))
- \[WIP\] Production release 4.9.11 [\#841](https://github.com/transitland/transitland-datastore/pull/841) ([irees](https://github.com/irees))
- Frequency based trips [\#828](https://github.com/transitland/transitland-datastore/pull/828) ([irees](https://github.com/irees))
- GeoJSON Serializer / Pagination [\#822](https://github.com/transitland/transitland-datastore/pull/822) ([irees](https://github.com/irees))
- Issue deactivation by entity [\#817](https://github.com/transitland/transitland-datastore/pull/817) ([doublestranded](https://github.com/doublestranded))

## [4.9.11](https://github.com/transitland/transitland-datastore/tree/4.9.11) (2016-10-25)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.10...4.9.11)

**Implemented enhancements:**

- consider sidekiq-status for reporting progress within jobs [\#446](https://github.com/transitland/transitland-datastore/issues/446)

**Closed issues:**

- Schedule adjustments to reduce conflicts [\#838](https://github.com/transitland/transitland-datastore/issues/838)
- include only one geometry for each route on routes endpoint [\#671](https://github.com/transitland/transitland-datastore/issues/671)

**Merged pull requests:**

- Valhalla runs at 3am UTC, not midnight; move 3 hrs forward. [\#840](https://github.com/transitland/transitland-datastore/pull/840) ([irees](https://github.com/irees))
- Adjust schedule to reduce conflicts [\#839](https://github.com/transitland/transitland-datastore/pull/839) ([irees](https://github.com/irees))
- update gems [\#837](https://github.com/transitland/transitland-datastore/pull/837) ([drewda](https://github.com/drewda))
- \[WIP\] Production release 4.9.10 [\#836](https://github.com/transitland/transitland-datastore/pull/836) ([doublestranded](https://github.com/doublestranded))
- Route rsps repr [\#827](https://github.com/transitland/transitland-datastore/pull/827) ([doublestranded](https://github.com/doublestranded))

## [4.9.10](https://github.com/transitland/transitland-datastore/tree/4.9.10) (2016-10-21)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.9...4.9.10)

**Fixed bugs:**

- Operator convex\_hull specs sometimes fail [\#833](https://github.com/transitland/transitland-datastore/issues/833)
- OSM conflation for stops has been failing a lot recently [\#830](https://github.com/transitland/transitland-datastore/issues/830)
- Issues on FeedVersions halting imports [\#825](https://github.com/transitland/transitland-datastore/issues/825)

**Closed issues:**

- Feed: sort by latest feed version import [\#823](https://github.com/transitland/transitland-datastore/issues/823)
- Turn on automatic feed import and schedule extension [\#795](https://github.com/transitland/transitland-datastore/issues/795)

**Merged pull requests:**

- using match\_array instead of eq in convex hull expects [\#834](https://github.com/transitland/transitland-datastore/pull/834) ([doublestranded](https://github.com/doublestranded))
- Tyr response guarding [\#832](https://github.com/transitland/transitland-datastore/pull/832) ([doublestranded](https://github.com/doublestranded))
- Pagination refactor and feed sort by latest feed version import [\#821](https://github.com/transitland/transitland-datastore/pull/821) ([irees](https://github.com/irees))
- Production release 4.9.9 [\#803](https://github.com/transitland/transitland-datastore/pull/803) ([irees](https://github.com/irees))

## [4.9.9](https://github.com/transitland/transitland-datastore/tree/4.9.9) (2016-10-14)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.8...4.9.9)

**Implemented enhancements:**

- rake task to populate `wheelchair\_accessible` and `bikes\_allowed` attributes on `Route` model [\#804](https://github.com/transitland/transitland-datastore/issues/804)
- RouteStopPattern onestopId only in JSON validator [\#684](https://github.com/transitland/transitland-datastore/issues/684)

**Fixed bugs:**

- OperatorsInFeed: Should be deleted when Operator is deleted [\#797](https://github.com/transitland/transitland-datastore/issues/797)

**Closed issues:**

- Feeds: Filter by import failure / success / in progress [\#815](https://github.com/transitland/transitland-datastore/issues/815)
- Operator delete: also remove OperatorInFeed records [\#807](https://github.com/transitland/transitland-datastore/issues/807)
- include issues in activity feed [\#793](https://github.com/transitland/transitland-datastore/issues/793)
- FeedMaintenanceService: Create issues when extending/enqueueing [\#792](https://github.com/transitland/transitland-datastore/issues/792)
- return meaningful info at `/api/v1/` including Datastore version number [\#719](https://github.com/transitland/transitland-datastore/issues/719)
- edit "stickiness" [\#570](https://github.com/transitland/transitland-datastore/issues/570)

**Merged pull requests:**

- Issue deprecation: ignore FeedVersions [\#824](https://github.com/transitland/transitland-datastore/pull/824) ([irees](https://github.com/irees))
- Feed: filter by latest import status [\#819](https://github.com/transitland/transitland-datastore/pull/819) ([irees](https://github.com/irees))
- Update gems correctly [\#818](https://github.com/transitland/transitland-datastore/pull/818) ([drewda](https://github.com/drewda))
- Delete OperatorsInFeed when Operator is deleted [\#814](https://github.com/transitland/transitland-datastore/pull/814) ([irees](https://github.com/irees))
- Activity feed: Feed maintenance [\#813](https://github.com/transitland/transitland-datastore/pull/813) ([irees](https://github.com/irees))
- API info [\#812](https://github.com/transitland/transitland-datastore/pull/812) ([drewda](https://github.com/drewda))
- Route accessibility rake task [\#811](https://github.com/transitland/transitland-datastore/pull/811) ([doublestranded](https://github.com/doublestranded))
- Revert "update gems" [\#810](https://github.com/transitland/transitland-datastore/pull/810) ([drewda](https://github.com/drewda))
- update gems [\#809](https://github.com/transitland/transitland-datastore/pull/809) ([drewda](https://github.com/drewda))
- Feed version maintenance: create Issues [\#808](https://github.com/transitland/transitland-datastore/pull/808) ([irees](https://github.com/irees))
- Issues without changesets [\#806](https://github.com/transitland/transitland-datastore/pull/806) ([doublestranded](https://github.com/doublestranded))
- Sticky attributes [\#790](https://github.com/transitland/transitland-datastore/pull/790) ([doublestranded](https://github.com/doublestranded))
- only onestopId required [\#789](https://github.com/transitland/transitland-datastore/pull/789) ([doublestranded](https://github.com/doublestranded))
- \[WIP\] Production release 4.9.8 [\#783](https://github.com/transitland/transitland-datastore/pull/783) ([irees](https://github.com/irees))

## [4.9.8](https://github.com/transitland/transitland-datastore/tree/4.9.8) (2016-09-22)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.7...4.9.8)

**Implemented enhancements:**

- Promote wheelchair boarding tag to Stop attr [\#800](https://github.com/transitland/transitland-datastore/issues/800)

**Fixed bugs:**

- FeedVersionUploader: remove\_any\_local\_cached\_copies [\#791](https://github.com/transitland/transitland-datastore/issues/791)
- OnestopID: Uniqueness constraint [\#779](https://github.com/transitland/transitland-datastore/issues/779)
- Operator: update convex hull as computed property [\#704](https://github.com/transitland/transitland-datastore/issues/704)

**Closed issues:**

- Automatically extend expiring FeedVersions [\#784](https://github.com/transitland/transitland-datastore/issues/784)
- Remove Issues on cleanup Entities task [\#768](https://github.com/transitland/transitland-datastore/issues/768)
- aggregate `wheelchair\_accessible` and `bikes\_allowed` on `Route` model [\#672](https://github.com/transitland/transitland-datastore/issues/672)

**Merged pull requests:**

- Route wheelchair\_accessible: remove debugging log line [\#802](https://github.com/transitland/transitland-datastore/pull/802) ([irees](https://github.com/irees))
- added wheelchair\_boarding to Stop as attribute [\#801](https://github.com/transitland/transitland-datastore/pull/801) ([doublestranded](https://github.com/doublestranded))
- Route: aggregate accessibility information [\#799](https://github.com/transitland/transitland-datastore/pull/799) ([irees](https://github.com/irees))
- FeedVersion: include HasTags concern [\#798](https://github.com/transitland/transitland-datastore/pull/798) ([irees](https://github.com/irees))
- Correctly rm cached files [\#796](https://github.com/transitland/transitland-datastore/pull/796) ([irees](https://github.com/irees))
- Modify extend\_feed\_version logging to reduce unnecessary queries [\#788](https://github.com/transitland/transitland-datastore/pull/788) ([irees](https://github.com/irees))
- OnestopID uniqueness constraints [\#786](https://github.com/transitland/transitland-datastore/pull/786) ([irees](https://github.com/irees))
- adding dependent destroy associations [\#785](https://github.com/transitland/transitland-datastore/pull/785) ([doublestranded](https://github.com/doublestranded))
- Automatically extend schedules [\#782](https://github.com/transitland/transitland-datastore/pull/782) ([irees](https://github.com/irees))
- Production release 4.9.7 [\#777](https://github.com/transitland/transitland-datastore/pull/777) ([irees](https://github.com/irees))

## [4.9.7](https://github.com/transitland/transitland-datastore/tree/4.9.7) (2016-09-12)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.6...4.9.7)

**Fixed bugs:**

- RSP distance duplicate points bug [\#773](https://github.com/transitland/transitland-datastore/issues/773)

**Closed issues:**

- Manual Changesets slow [\#780](https://github.com/transitland/transitland-datastore/issues/780)

**Merged pull requests:**

- for now, only bulk deactivate if import or issue-resolving [\#781](https://github.com/transitland/transitland-datastore/pull/781) ([doublestranded](https://github.com/doublestranded))
- Dist segment matching fix [\#778](https://github.com/transitland/transitland-datastore/pull/778) ([doublestranded](https://github.com/doublestranded))
- Production release 4.9.6 [\#759](https://github.com/transitland/transitland-datastore/pull/759) ([irees](https://github.com/irees))

## [4.9.6](https://github.com/transitland/transitland-datastore/tree/4.9.6) (2016-09-09)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.5...4.9.6)

**Implemented enhancements:**

- Deactivation \(deprecation\) of Issues [\#766](https://github.com/transitland/transitland-datastore/issues/766)
- Automatically create rsp\_line\_inaccurate issues [\#752](https://github.com/transitland/transitland-datastore/issues/752)

**Fixed bugs:**

- Issue deprecation spec sometimes fails [\#775](https://github.com/transitland/transitland-datastore/issues/775)
- CarrierWave: cache files not always deleted [\#770](https://github.com/transitland/transitland-datastore/issues/770)
- Query Issues by Feed from Entities [\#764](https://github.com/transitland/transitland-datastore/issues/764)
- Move Changeset apply worker to default Sidekiq queue [\#762](https://github.com/transitland/transitland-datastore/issues/762)
- if an operator only has two stops, its convex hull is a LineString rather than a Polygon [\#714](https://github.com/transitland/transitland-datastore/issues/714)

**Closed issues:**

- model methods and rake task to "push out" ScheduleStopPairs end calendar date [\#647](https://github.com/transitland/transitland-datastore/issues/647)

**Merged pull requests:**

- adding TimeCop to spec [\#776](https://github.com/transitland/transitland-datastore/pull/776) ([doublestranded](https://github.com/doublestranded))
- last\_fetched\_at did not update unless FeedVersion was new [\#774](https://github.com/transitland/transitland-datastore/pull/774) ([irees](https://github.com/irees))
- Bump gtfs: relative redirect fix [\#772](https://github.com/transitland/transitland-datastore/pull/772) ([irees](https://github.com/irees))
- Feed fetch: disk space leak [\#769](https://github.com/transitland/transitland-datastore/pull/769) ([irees](https://github.com/irees))
- Issues deactivation [\#767](https://github.com/transitland/transitland-datastore/pull/767) ([doublestranded](https://github.com/doublestranded))
- issues queryable by feed from entities [\#765](https://github.com/transitland/transitland-datastore/pull/765) ([doublestranded](https://github.com/doublestranded))
- Changeset worker fix [\#763](https://github.com/transitland/transitland-datastore/pull/763) ([doublestranded](https://github.com/doublestranded))
- update gems [\#760](https://github.com/transitland/transitland-datastore/pull/760) ([drewda](https://github.com/drewda))
- FeedVersion: extend schedule [\#758](https://github.com/transitland/transitland-datastore/pull/758) ([irees](https://github.com/irees))
- Operator bbox fix [\#757](https://github.com/transitland/transitland-datastore/pull/757) ([doublestranded](https://github.com/doublestranded))
- Rsp line inaccurate auto issues [\#756](https://github.com/transitland/transitland-datastore/pull/756) ([doublestranded](https://github.com/doublestranded))
- Production release 4.9.5 [\#755](https://github.com/transitland/transitland-datastore/pull/755) ([doublestranded](https://github.com/doublestranded))

## [4.9.5](https://github.com/transitland/transitland-datastore/tree/4.9.5) (2016-08-24)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.4...4.9.5)

**Closed issues:**

- upgrade to Ruby 2.3 [\#691](https://github.com/transitland/transitland-datastore/issues/691)

**Merged pull requests:**

- Production release 4.9.4 [\#738](https://github.com/transitland/transitland-datastore/pull/738) ([irees](https://github.com/irees))
- upgrade to Ruby 2.3.1 [\#692](https://github.com/transitland/transitland-datastore/pull/692) ([drewda](https://github.com/drewda))

## [4.9.4](https://github.com/transitland/transitland-datastore/tree/4.9.4) (2016-08-24)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.3...4.9.4)

**Implemented enhancements:**

- Issue controller update method fix and improvement [\#740](https://github.com/transitland/transitland-datastore/issues/740)
- Integrate memory\_profiling rake with CircleCI [\#733](https://github.com/transitland/transitland-datastore/issues/733)
- Changeset::Error errors to array [\#730](https://github.com/transitland/transitland-datastore/issues/730)
- Updating SSP distances in computed attributes [\#665](https://github.com/transitland/transitland-datastore/issues/665)

**Fixed bugs:**

- For profiling rake task some local environs failed [\#749](https://github.com/transitland/transitland-datastore/issues/749)
- Issue controller update method fix and improvement [\#740](https://github.com/transitland/transitland-datastore/issues/740)
- Updating SSP distances in computed attributes [\#665](https://github.com/transitland/transitland-datastore/issues/665)

**Closed issues:**

- specify how many feeds enqueue\_next\_feed\_versions re-imports and any feeds to skip [\#753](https://github.com/transitland/transitland-datastore/issues/753)
- Automate routine new feed version imports [\#745](https://github.com/transitland/transitland-datastore/issues/745)
- background application of changesets through API [\#634](https://github.com/transitland/transitland-datastore/issues/634)
- where\_active/where\_inactive scope for all entities [\#540](https://github.com/transitland/transitland-datastore/issues/540)

**Merged pull requests:**

- Enqueue next feed versions limit [\#754](https://github.com/transitland/transitland-datastore/pull/754) ([irees](https://github.com/irees))
- Upgrade Rails to 4.2.7.1 & update gems [\#751](https://github.com/transitland/transitland-datastore/pull/751) ([drewda](https://github.com/drewda))
- fixing OperatorInFeed bug and some comments [\#750](https://github.com/transitland/transitland-datastore/pull/750) ([doublestranded](https://github.com/doublestranded))
- Daily crontab: enqueue next feed version [\#744](https://github.com/transitland/transitland-datastore/pull/744) ([irees](https://github.com/irees))
- Issues controller update fix [\#741](https://github.com/transitland/transitland-datastore/pull/741) ([doublestranded](https://github.com/doublestranded))
- Entity: where\_imported\_from\_active\_feed\_version [\#739](https://github.com/transitland/transitland-datastore/pull/739) ([irees](https://github.com/irees))
- Circle ci profile logging [\#734](https://github.com/transitland/transitland-datastore/pull/734) ([doublestranded](https://github.com/doublestranded))
- ChangesetApplyWorker [\#732](https://github.com/transitland/transitland-datastore/pull/732) ([irees](https://github.com/irees))
- Production release 4.9.3 [\#727](https://github.com/transitland/transitland-datastore/pull/727) ([irees](https://github.com/irees))
- Ssp distance computed attribute [\#717](https://github.com/transitland/transitland-datastore/pull/717) ([doublestranded](https://github.com/doublestranded))

## [4.9.3](https://github.com/transitland/transitland-datastore/tree/4.9.3) (2016-08-15)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.2...4.9.3)

**Implemented enhancements:**

- Query Issues by Feed [\#724](https://github.com/transitland/transitland-datastore/issues/724)

**Fixed bugs:**

- Create Issue EntitiesWithIssues bug [\#722](https://github.com/transitland/transitland-datastore/issues/722)

**Closed issues:**

- Feed fetcher schedule fix [\#736](https://github.com/transitland/transitland-datastore/issues/736)
- GTFS: Configure temporary directory [\#718](https://github.com/transitland/transitland-datastore/issues/718)
- RSP memory use reduction part 1 [\#715](https://github.com/transitland/transitland-datastore/issues/715)
- automatically removed outdated ScheduleStopPairs after feed re-imports \(and delete any outdated SSPs currently in database\) [\#690](https://github.com/transitland/transitland-datastore/issues/690)
- in Stop, StopStation, and StopPlatform list the vehicle\_types that serve it [\#632](https://github.com/transitland/transitland-datastore/issues/632)
- Case-insensitive queries [\#578](https://github.com/transitland/transitland-datastore/issues/578)
- throw error when `vehicle\_type` value is invalid [\#474](https://github.com/transitland/transitland-datastore/issues/474)
- Profiling and benchmarking of RSP generation process \(and FeedEater\) [\#469](https://github.com/transitland/transitland-datastore/issues/469)

**Merged pull requests:**

- Feed fetcher service fix [\#737](https://github.com/transitland/transitland-datastore/pull/737) ([irees](https://github.com/irees))
- Memory profiler fix [\#731](https://github.com/transitland/transitland-datastore/pull/731) ([doublestranded](https://github.com/doublestranded))
- Baldur/memprofile work [\#729](https://github.com/transitland/transitland-datastore/pull/729) ([doublestranded](https://github.com/doublestranded))
- AllowFiltering: Case insensitive queries [\#728](https://github.com/transitland/transitland-datastore/pull/728) ([irees](https://github.com/irees))
- Fix Milan: empty stop timezone [\#726](https://github.com/transitland/transitland-datastore/pull/726) ([irees](https://github.com/irees))
- Query by feed [\#725](https://github.com/transitland/transitland-datastore/pull/725) ([doublestranded](https://github.com/doublestranded))
- ensuring distinct entities\_with\_issues created for each new issue [\#723](https://github.com/transitland/transitland-datastore/pull/723) ([doublestranded](https://github.com/doublestranded))
- Config: GTFS\_TMPDIR\_BASEPATH [\#721](https://github.com/transitland/transitland-datastore/pull/721) ([irees](https://github.com/irees))
- Rsp optimization 1 [\#720](https://github.com/transitland/transitland-datastore/pull/720) ([doublestranded](https://github.com/doublestranded))
- Production release 4.9.2 [\#716](https://github.com/transitland/transitland-datastore/pull/716) ([irees](https://github.com/irees))
- Stop: served\_by\_vehicle\_types [\#712](https://github.com/transitland/transitland-datastore/pull/712) ([irees](https://github.com/irees))

## [4.9.2](https://github.com/transitland/transitland-datastore/tree/4.9.2) (2016-07-28)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.1...4.9.2)

**Implemented enhancements:**

- ScheduleStopPair: when a trip has no headsign, fall back to name of last stop [\#705](https://github.com/transitland/transitland-datastore/issues/705)

**Fixed bugs:**

- Issues request returning routes on next page [\#706](https://github.com/transitland/transitland-datastore/issues/706)
- Issues not saving or appearing on dev or prod [\#688](https://github.com/transitland/transitland-datastore/issues/688)

**Merged pull requests:**

- SSP: headsign fallback [\#711](https://github.com/transitland/transitland-datastore/pull/711) ([irees](https://github.com/irees))
- Update gems [\#709](https://github.com/transitland/transitland-datastore/pull/709) ([drewda](https://github.com/drewda))
- FeedVersion activation: delete old FeedVersion SSPs [\#708](https://github.com/transitland/transitland-datastore/pull/708) ([irees](https://github.com/irees))
- fixed for next page pagination [\#707](https://github.com/transitland/transitland-datastore/pull/707) ([doublestranded](https://github.com/doublestranded))
- GTFSGraph: Skip agencies without stops [\#703](https://github.com/transitland/transitland-datastore/pull/703) ([irees](https://github.com/irees))
- production release 4.9.1 [\#699](https://github.com/transitland/transitland-datastore/pull/699) ([drewda](https://github.com/drewda))

## [4.9.1](https://github.com/transitland/transitland-datastore/tree/4.9.1) (2016-07-22)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.9.0...4.9.1)

**Implemented enhancements:**

- Coordinates in JSON are sometimes strings, not float [\#695](https://github.com/transitland/transitland-datastore/issues/695)

**Fixed bugs:**

- CircleCI failing on onestop-id-tidy branch with issue specs [\#693](https://github.com/transitland/transitland-datastore/issues/693)
- FeedEater import succeeds, but doesn't persist stops/routes/SSPs because of Exception on ChangePayload validation error [\#687](https://github.com/transitland/transitland-datastore/issues/687)
- OnestopIDs: Improve name filter [\#685](https://github.com/transitland/transitland-datastore/issues/685)

**Closed issues:**

- HashHelpers.merge\_hashes filters out nil-like values [\#686](https://github.com/transitland/transitland-datastore/issues/686)

**Merged pull requests:**

- Stop OnestopID: Filter special characters [\#702](https://github.com/transitland/transitland-datastore/pull/702) ([irees](https://github.com/irees))
- HashHelpers: dont remove empty keys [\#698](https://github.com/transitland/transitland-datastore/pull/698) ([irees](https://github.com/irees))
- Encode BigDecimal as float [\#697](https://github.com/transitland/transitland-datastore/pull/697) ([irees](https://github.com/irees))
- JSON Schema: Stop osmWayId [\#696](https://github.com/transitland/transitland-datastore/pull/696) ([irees](https://github.com/irees))
- removing duplicate entities in quality check spec [\#694](https://github.com/transitland/transitland-datastore/pull/694) ([doublestranded](https://github.com/doublestranded))
- Production release 4.9.0 [\#678](https://github.com/transitland/transitland-datastore/pull/678) ([drewda](https://github.com/drewda))

## [4.9.0](https://github.com/transitland/transitland-datastore/tree/4.9.0) (2016-07-15)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.8.8...4.9.0)

**Implemented enhancements:**

- Add feed version to Issues controller [\#664](https://github.com/transitland/transitland-datastore/issues/664)

**Fixed bugs:**

- Issue controller query param issue\_type not returning [\#681](https://github.com/transitland/transitland-datastore/issues/681)
- logstasher gem error [\#674](https://github.com/transitland/transitland-datastore/issues/674)
- Forth Worth & other feeds: Changeset::Error Couldn't find Stop [\#660](https://github.com/transitland/transitland-datastore/issues/660)

**Closed issues:**

- SSP 'where\_active' performance [\#657](https://github.com/transitland/transitland-datastore/issues/657)
- "issues" and "quality checks" [\#569](https://github.com/transitland/transitland-datastore/issues/569)

**Merged pull requests:**

- Station serializer: timezones [\#683](https://github.com/transitland/transitland-datastore/pull/683) ([irees](https://github.com/irees))
- Issue type fix [\#682](https://github.com/transitland/transitland-datastore/pull/682) ([doublestranded](https://github.com/doublestranded))
- upgrade to Rails 4.2.7 and update gems [\#680](https://github.com/transitland/transitland-datastore/pull/680) ([drewda](https://github.com/drewda))
- SSP: disable where\_active default scope [\#679](https://github.com/transitland/transitland-datastore/pull/679) ([irees](https://github.com/irees))
- rolling back to previous version of logstasher gem [\#675](https://github.com/transitland/transitland-datastore/pull/675) ([drewda](https://github.com/drewda))
- Update gems [\#673](https://github.com/transitland/transitland-datastore/pull/673) ([drewda](https://github.com/drewda))
- Issues with feed version [\#670](https://github.com/transitland/transitland-datastore/pull/670) ([doublestranded](https://github.com/doublestranded))
- Production release 4.8.8 [\#659](https://github.com/transitland/transitland-datastore/pull/659) ([irees](https://github.com/irees))
- Issues [\#599](https://github.com/transitland/transitland-datastore/pull/599) ([doublestranded](https://github.com/doublestranded))

## [4.8.8](https://github.com/transitland/transitland-datastore/tree/4.8.8) (2016-07-07)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.8.7...4.8.8)

**Implemented enhancements:**

- Updating RSP distances when related entities change with changeset [\#525](https://github.com/transitland/transitland-datastore/issues/525)

**Fixed bugs:**

- RSP not found in feeds where not all operators are imported [\#377](https://github.com/transitland/transitland-datastore/issues/377)

**Closed issues:**

- Route controller: serves stops [\#654](https://github.com/transitland/transitland-datastore/issues/654)
- Feeds controller: Filter by latest\_fetch\_exception\_log [\#651](https://github.com/transitland/transitland-datastore/issues/651)
- Station Hierarchy Import [\#257](https://github.com/transitland/transitland-datastore/issues/257)
- Station Hierarchy data model [\#256](https://github.com/transitland/transitland-datastore/issues/256)

**Merged pull requests:**

- Compatibility: Stop osm\_way\_id tag [\#663](https://github.com/transitland/transitland-datastore/pull/663) ([irees](https://github.com/irees))
- Add imported\_from\_\* params to pagination links [\#662](https://github.com/transitland/transitland-datastore/pull/662) ([irees](https://github.com/irees))
- GTFSGraph: Disable StopTransfer import [\#661](https://github.com/transitland/transitland-datastore/pull/661) ([irees](https://github.com/irees))
- EIFF: scope where\_imported\_from\_feed [\#658](https://github.com/transitland/transitland-datastore/pull/658) ([irees](https://github.com/irees))
- Stop JSON Schema fixes [\#656](https://github.com/transitland/transitland-datastore/pull/656) ([irees](https://github.com/irees))
- Computed attributes [\#655](https://github.com/transitland/transitland-datastore/pull/655) ([doublestranded](https://github.com/doublestranded))
- Route controller: serves stops [\#653](https://github.com/transitland/transitland-datastore/pull/653) ([irees](https://github.com/irees))
- Feeds controller: Filter by latest\_fetch\_exception\_log [\#652](https://github.com/transitland/transitland-datastore/pull/652) ([irees](https://github.com/irees))
- added stops\_served\_by\_route to route controller [\#650](https://github.com/transitland/transitland-datastore/pull/650) ([doublestranded](https://github.com/doublestranded))
- Fixing 1 stop, 2 stop times level 2 import bug [\#649](https://github.com/transitland/transitland-datastore/pull/649) ([doublestranded](https://github.com/doublestranded))
- SSP import: skip if missing entities [\#648](https://github.com/transitland/transitland-datastore/pull/648) ([irees](https://github.com/irees))
- Production release 4.8.7 [\#645](https://github.com/transitland/transitland-datastore/pull/645) ([irees](https://github.com/irees))
- Station hierarchy 4 [\#572](https://github.com/transitland/transitland-datastore/pull/572) ([irees](https://github.com/irees))

## [4.8.7](https://github.com/transitland/transitland-datastore/tree/4.8.7) (2016-06-23)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.8.6...4.8.7)

**Fixed bugs:**

- can't query by both tag and import level simultaneously [\#612](https://github.com/transitland/transitland-datastore/issues/612)

**Merged pull requests:**

- Fix ambiguous tags query [\#644](https://github.com/transitland/transitland-datastore/pull/644) ([irees](https://github.com/irees))
- \[WIP\] production release 4.8.6 [\#628](https://github.com/transitland/transitland-datastore/pull/628) ([drewda](https://github.com/drewda))

## [4.8.6](https://github.com/transitland/transitland-datastore/tree/4.8.6) (2016-06-21)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.8.5...4.8.6)

**Fixed bugs:**

- geometry nil value [\#636](https://github.com/transitland/transitland-datastore/issues/636)
- RSP generation should handle trips with 1 stop [\#600](https://github.com/transitland/transitland-datastore/issues/600)

**Closed issues:**

- spread feed fetching throughout the day [\#629](https://github.com/transitland/transitland-datastore/issues/629)
- remove unnecessary database indices [\#626](https://github.com/transitland/transitland-datastore/issues/626)
- stagger feed fetching [\#456](https://github.com/transitland/transitland-datastore/issues/456)

**Merged pull requests:**

- Rsp geom generation bugs fix [\#642](https://github.com/transitland/transitland-datastore/pull/642) ([doublestranded](https://github.com/doublestranded))
- only remove extraneous indexes if they exist [\#641](https://github.com/transitland/transitland-datastore/pull/641) ([drewda](https://github.com/drewda))
- update gems [\#638](https://github.com/transitland/transitland-datastore/pull/638) ([drewda](https://github.com/drewda))
- Stagger feed fetch [\#637](https://github.com/transitland/transitland-datastore/pull/637) ([drewda](https://github.com/drewda))
- Rake task: enqueue next feed version [\#630](https://github.com/transitland/transitland-datastore/pull/630) ([irees](https://github.com/irees))
- Remove unnecessary database indices [\#627](https://github.com/transitland/transitland-datastore/pull/627) ([drewda](https://github.com/drewda))
- Production deploy 4.8.5 [\#625](https://github.com/transitland/transitland-datastore/pull/625) ([irees](https://github.com/irees))

## [4.8.5](https://github.com/transitland/transitland-datastore/tree/4.8.5) (2016-06-13)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.8.4...4.8.5)

**Fixed bugs:**

- when import is in progress, activity updates show import as unsuccessful [\#606](https://github.com/transitland/transitland-datastore/issues/606)

**Closed issues:**

- Ambiguous 'tags' [\#619](https://github.com/transitland/transitland-datastore/issues/619)
- Set block\_id in SSPs [\#613](https://github.com/transitland/transitland-datastore/issues/613)
- Slow SSP pagination [\#610](https://github.com/transitland/transitland-datastore/issues/610)

**Merged pull requests:**

- activate PgHero in production [\#622](https://github.com/transitland/transitland-datastore/pull/622) ([drewda](https://github.com/drewda))
- Import trip block\_id [\#621](https://github.com/transitland/transitland-datastore/pull/621) ([irees](https://github.com/irees))
- Activity update bug [\#620](https://github.com/transitland/transitland-datastore/pull/620) ([drewda](https://github.com/drewda))
- update gems [\#618](https://github.com/transitland/transitland-datastore/pull/618) ([drewda](https://github.com/drewda))
- after\_create\_making\_history after all changes in payload [\#617](https://github.com/transitland/transitland-datastore/pull/617) ([irees](https://github.com/irees))
- logging initializer and gtfs\_graph log function [\#615](https://github.com/transitland/transitland-datastore/pull/615) ([doublestranded](https://github.com/doublestranded))
- SSP pagination performance [\#611](https://github.com/transitland/transitland-datastore/pull/611) ([irees](https://github.com/irees))
- Production release 4.8.4 [\#609](https://github.com/transitland/transitland-datastore/pull/609) ([irees](https://github.com/irees))

## [4.8.4](https://github.com/transitland/transitland-datastore/tree/4.8.4) (2016-05-27)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.8.3...4.8.4)

**Fixed bugs:**

- Sidekiq dashboard isn't allowing admins to delete enqueued jobs [\#445](https://github.com/transitland/transitland-datastore/issues/445)

**Closed issues:**

- Tyr transit costing update [\#607](https://github.com/transitland/transitland-datastore/issues/607)

**Merged pull requests:**

- Tyr costing transit [\#608](https://github.com/transitland/transitland-datastore/pull/608) ([irees](https://github.com/irees))
- fix for: Sidekiq dashboard isn't allowing admins to delete enqueued jobs [\#605](https://github.com/transitland/transitland-datastore/pull/605) ([drewda](https://github.com/drewda))
- update gems [\#604](https://github.com/transitland/transitland-datastore/pull/604) ([drewda](https://github.com/drewda))
- Production release 4.8.3 [\#603](https://github.com/transitland/transitland-datastore/pull/603) ([irees](https://github.com/irees))

## [4.8.3](https://github.com/transitland/transitland-datastore/tree/4.8.3) (2016-05-24)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.8.2...4.8.3)

**Closed issues:**

- Feed filter by active\_feed\_version import\_level [\#595](https://github.com/transitland/transitland-datastore/issues/595)
- Temporary files not being cleaned up [\#594](https://github.com/transitland/transitland-datastore/issues/594)
- allow `per\_page=false` to turn off pagination [\#592](https://github.com/transitland/transitland-datastore/issues/592)

**Merged pull requests:**

- Temporary file cleanup [\#602](https://github.com/transitland/transitland-datastore/pull/602) ([irees](https://github.com/irees))
- temporary fix to ignore trips with less than 2 unique stops [\#601](https://github.com/transitland/transitland-datastore/pull/601) ([doublestranded](https://github.com/doublestranded))
- updating gems [\#598](https://github.com/transitland/transitland-datastore/pull/598) ([drewda](https://github.com/drewda))
- allow `per\_page=false` to turn off pagination [\#597](https://github.com/transitland/transitland-datastore/pull/597) ([drewda](https://github.com/drewda))
- Feed active feed version import\_level [\#596](https://github.com/transitland/transitland-datastore/pull/596) ([irees](https://github.com/irees))
- Production release 4.8.2 [\#593](https://github.com/transitland/transitland-datastore/pull/593) ([irees](https://github.com/irees))

## [4.8.2](https://github.com/transitland/transitland-datastore/tree/4.8.2) (2016-05-11)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.8.1...4.8.2)

**Closed issues:**

- Expired Feed queries [\#591](https://github.com/transitland/transitland-datastore/issues/591)
- Operators: filter by name, short\_name [\#588](https://github.com/transitland/transitland-datastore/issues/588)
- Operator: add name and short\_name to aggregate endpoint [\#587](https://github.com/transitland/transitland-datastore/issues/587)

**Merged pull requests:**

- ChangesetError bug fix [\#590](https://github.com/transitland/transitland-datastore/pull/590) ([doublestranded](https://github.com/doublestranded))
- Operators filter name [\#589](https://github.com/transitland/transitland-datastore/pull/589) ([irees](https://github.com/irees))
- Operator aggregate: add name and short\_name [\#586](https://github.com/transitland/transitland-datastore/pull/586) ([irees](https://github.com/irees))
- Production release 4.8.1 [\#584](https://github.com/transitland/transitland-datastore/pull/584) ([irees](https://github.com/irees))
- Feed queries: valid, expired, updateable [\#581](https://github.com/transitland/transitland-datastore/pull/581) ([irees](https://github.com/irees))

## [4.8.1](https://github.com/transitland/transitland-datastore/tree/4.8.1) (2016-05-06)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.8.0...4.8.1)

**Implemented enhancements:**

- Support for non-ASCII onestop ids [\#579](https://github.com/transitland/transitland-datastore/issues/579)

**Fixed bugs:**

- RouteStopPattern creation error in `f-dpmg-rta` [\#573](https://github.com/transitland/transitland-datastore/issues/573)

**Closed issues:**

- Onestop Id exceptions [\#583](https://github.com/transitland/transitland-datastore/issues/583)
- Onestop Id Invalid Geometry Hash [\#575](https://github.com/transitland/transitland-datastore/issues/575)

**Merged pull requests:**

- Onestop ID exceptions, name fallbacks [\#582](https://github.com/transitland/transitland-datastore/pull/582) ([irees](https://github.com/irees))
- Unicode onestop ids [\#580](https://github.com/transitland/transitland-datastore/pull/580) ([doublestranded](https://github.com/doublestranded))
- Handle trips one stop time [\#577](https://github.com/transitland/transitland-datastore/pull/577) ([doublestranded](https://github.com/doublestranded))
- Onestop id name truncation [\#576](https://github.com/transitland/transitland-datastore/pull/576) ([doublestranded](https://github.com/doublestranded))
- production release 4.8 [\#574](https://github.com/transitland/transitland-datastore/pull/574) ([drewda](https://github.com/drewda))

## [4.8.0](https://github.com/transitland/transitland-datastore/tree/4.8.0) (2016-04-22)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.7.11...4.8.0)

**Closed issues:**

- Improve activity feed [\#564](https://github.com/transitland/transitland-datastore/issues/564)
- FeedVersion requires sha1 [\#560](https://github.com/transitland/transitland-datastore/issues/560)
- Feeds controller: last\_imported\_at [\#556](https://github.com/transitland/transitland-datastore/issues/556)
- return list of all possible country/state/metro for operators [\#549](https://github.com/transitland/transitland-datastore/issues/549)
- Timezone is not set for some stops in Transitland [\#528](https://github.com/transitland/transitland-datastore/issues/528)
- before RSP launch, clear out any duplicate or outdated RSPs [\#526](https://github.com/transitland/transitland-datastore/issues/526)
- AC Transit EIFF issues [\#492](https://github.com/transitland/transitland-datastore/issues/492)
- Datastore activity feed [\#395](https://github.com/transitland/transitland-datastore/issues/395)
- Onestop ID Foreign Key in Schedule Stop Pairs [\#318](https://github.com/transitland/transitland-datastore/issues/318)
- handle ZIP files that contain nested GTFS feeds \(and CSV files in a nested directory\) [\#316](https://github.com/transitland/transitland-datastore/issues/316)

**Merged pull requests:**

- return list of all possible country/state/metro for operators [\#568](https://github.com/transitland/transitland-datastore/pull/568) ([drewda](https://github.com/drewda))
- update gems [\#567](https://github.com/transitland/transitland-datastore/pull/567) ([drewda](https://github.com/drewda))
- Activity update improvements [\#566](https://github.com/transitland/transitland-datastore/pull/566) ([drewda](https://github.com/drewda))
- Stop timezone required [\#563](https://github.com/transitland/transitland-datastore/pull/563) ([irees](https://github.com/irees))
- Fix issue with Feed Version Controller Spec [\#559](https://github.com/transitland/transitland-datastore/pull/559) ([irees](https://github.com/irees))
- production release 4.7.11 [\#558](https://github.com/transitland/transitland-datastore/pull/558) ([drewda](https://github.com/drewda))
- Nested GTFS [\#545](https://github.com/transitland/transitland-datastore/pull/545) ([irees](https://github.com/irees))
- activity feed [\#476](https://github.com/transitland/transitland-datastore/pull/476) ([drewda](https://github.com/drewda))

## [4.7.11](https://github.com/transitland/transitland-datastore/tree/4.7.11) (2016-04-13)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.7.10...4.7.11)

**Merged pull requests:**

- Feed query last updated since [\#557](https://github.com/transitland/transitland-datastore/pull/557) ([irees](https://github.com/irees))
- production release 4.7.10 [\#551](https://github.com/transitland/transitland-datastore/pull/551) ([drewda](https://github.com/drewda))

## [4.7.10](https://github.com/transitland/transitland-datastore/tree/4.7.10) (2016-04-09)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.7.9...4.7.10)

**Fixed bugs:**

- re-import of an existing feed now fails when operator has customized Onestop ID [\#552](https://github.com/transitland/transitland-datastore/issues/552)
- README includes a link that no longer works [\#498](https://github.com/transitland/transitland-datastore/issues/498)

**Closed issues:**

- allow download of feed versions from CDN [\#404](https://github.com/transitland/transitland-datastore/issues/404)

**Merged pull requests:**

- allow download of feed versions from CDN [\#555](https://github.com/transitland/transitland-datastore/pull/555) ([drewda](https://github.com/drewda))
- move docs to website [\#554](https://github.com/transitland/transitland-datastore/pull/554) ([drewda](https://github.com/drewda))
- fix for: re-import of an existing feed now fails when operator has customized Onestop ID [\#553](https://github.com/transitland/transitland-datastore/pull/553) ([drewda](https://github.com/drewda))

## [4.7.9](https://github.com/transitland/transitland-datastore/tree/4.7.9) (2016-04-06)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.7.8...4.7.9)

**Closed issues:**

- Handling trips with no rsp generation [\#543](https://github.com/transitland/transitland-datastore/issues/543)
- GTFS Graph: Update entity attributes on subsequent imports of a feed/feed version [\#464](https://github.com/transitland/transitland-datastore/issues/464)
- the transitland@mapzen.com user shouldn't get notifications about changeset creation and application [\#411](https://github.com/transitland/transitland-datastore/issues/411)
- RouteStopPatterns: store shape ID in identifiers \(rather than tags\) [\#401](https://github.com/transitland/transitland-datastore/issues/401)

**Merged pull requests:**

- Shape identifiers [\#550](https://github.com/transitland/transitland-datastore/pull/550) ([doublestranded](https://github.com/doublestranded))
- update gems [\#548](https://github.com/transitland/transitland-datastore/pull/548) ([drewda](https://github.com/drewda))
- Interpolation of outlier stops [\#547](https://github.com/transitland/transitland-datastore/pull/547) ([doublestranded](https://github.com/doublestranded))
- adding stop\_distances to rsp geojson properties [\#546](https://github.com/transitland/transitland-datastore/pull/546) ([doublestranded](https://github.com/doublestranded))
- Handle trips without Route Stop Patterns [\#544](https://github.com/transitland/transitland-datastore/pull/544) ([doublestranded](https://github.com/doublestranded))
- Production release 4.7.8 [\#542](https://github.com/transitland/transitland-datastore/pull/542) ([irees](https://github.com/irees))
- Feed transition entity updates [\#536](https://github.com/transitland/transitland-datastore/pull/536) ([doublestranded](https://github.com/doublestranded))

## [4.7.8](https://github.com/transitland/transitland-datastore/tree/4.7.8) (2016-03-31)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.7.7...4.7.8)

**Implemented enhancements:**

- Distance Calculation 2.0 Documentation and Tweaks [\#530](https://github.com/transitland/transitland-datastore/issues/530)
- Refactor Distance Calculation [\#477](https://github.com/transitland/transitland-datastore/issues/477)

**Fixed bugs:**

- where\_import\_level should return unique results [\#537](https://github.com/transitland/transitland-datastore/issues/537)

**Closed issues:**

- rebuild operator convex hulls on production [\#516](https://github.com/transitland/transitland-datastore/issues/516)

**Merged pull requests:**

- Rsp distance caching [\#541](https://github.com/transitland/transitland-datastore/pull/541) ([doublestranded](https://github.com/doublestranded))
- Fix duplicate import\_level results [\#539](https://github.com/transitland/transitland-datastore/pull/539) ([irees](https://github.com/irees))
- Distance calc 2 refinements [\#535](https://github.com/transitland/transitland-datastore/pull/535) ([doublestranded](https://github.com/doublestranded))
- Production release 4.7.7 [\#534](https://github.com/transitland/transitland-datastore/pull/534) ([irees](https://github.com/irees))
- rake task to rebuild operator convex hulls [\#521](https://github.com/transitland/transitland-datastore/pull/521) ([drewda](https://github.com/drewda))

## [4.7.7](https://github.com/transitland/transitland-datastore/tree/4.7.7) (2016-03-24)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.7.6...4.7.7)

**Closed issues:**

- limit Onestop IDs to 64 characters in length [\#512](https://github.com/transitland/transitland-datastore/issues/512)

**Merged pull requests:**

- Maximum Onestop ID Length [\#533](https://github.com/transitland/transitland-datastore/pull/533) ([irees](https://github.com/irees))

## [4.7.6](https://github.com/transitland/transitland-datastore/tree/4.7.6) (2016-03-24)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.7.5...4.7.6)

**Fixed bugs:**

- Operator JSON schema fix: shortName [\#524](https://github.com/transitland/transitland-datastore/issues/524)
- AC Transit re-import fails [\#520](https://github.com/transitland/transitland-datastore/issues/520)

**Closed issues:**

- Import levels query parameter for operator, route, stop, rsp API endpoints [\#472](https://github.com/transitland/transitland-datastore/issues/472)
- FeedInfo: Warning for existing Feed or Operator [\#471](https://github.com/transitland/transitland-datastore/issues/471)
- an integration test that tests a new version of a feed being imported [\#400](https://github.com/transitland/transitland-datastore/issues/400)

**Merged pull requests:**

- Entity import level scope [\#529](https://github.com/transitland/transitland-datastore/pull/529) ([irees](https://github.com/irees))
- Feed import integration tests, Phase 1 [\#527](https://github.com/transitland/transitland-datastore/pull/527) ([doublestranded](https://github.com/doublestranded))
- production release 4.7.5 [\#519](https://github.com/transitland/transitland-datastore/pull/519) ([drewda](https://github.com/drewda))
- FeedInfo: Warning for existing Feed or Operator [\#470](https://github.com/transitland/transitland-datastore/pull/470) ([irees](https://github.com/irees))

## [4.7.5](https://github.com/transitland/transitland-datastore/tree/4.7.5) (2016-03-18)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.7.4...4.7.5)

**Implemented enhancements:**

- Distance Calculation 2.0 [\#515](https://github.com/transitland/transitland-datastore/issues/515)
- Evaluate distances separate method [\#509](https://github.com/transitland/transitland-datastore/issues/509)
- Stop adding first/last stops to route stop pattern geometry [\#490](https://github.com/transitland/transitland-datastore/issues/490)

**Fixed bugs:**

- `route\_stop\_patterns\_by\_onestop\_id` should appear for routes [\#510](https://github.com/transitland/transitland-datastore/issues/510)
- Evaluate distances separate method [\#509](https://github.com/transitland/transitland-datastore/issues/509)
- automatic fetch of newly created feeds fails [\#488](https://github.com/transitland/transitland-datastore/issues/488)

**Closed issues:**

- improve API queries for route color [\#514](https://github.com/transitland/transitland-datastore/issues/514)
- Operator.from\_gtfs convex hull [\#508](https://github.com/transitland/transitland-datastore/issues/508)
- route `operatedBy` and stop `servedBy` query params should be under\_scored, rather than camelCased [\#475](https://github.com/transitland/transitland-datastore/issues/475)
- FeedInfo "progress bar" [\#441](https://github.com/transitland/transitland-datastore/issues/441)
- Route Stop Pattern documentation [\#415](https://github.com/transitland/transitland-datastore/issues/415)

**Merged pull requests:**

- Operator schema shortName [\#523](https://github.com/transitland/transitland-datastore/pull/523) ([irees](https://github.com/irees))
- update gems [\#522](https://github.com/transitland/transitland-datastore/pull/522) ([drewda](https://github.com/drewda))
- allow users to query API for all routes that have a color defined [\#518](https://github.com/transitland/transitland-datastore/pull/518) ([drewda](https://github.com/drewda))
- Stop ordered segment matching [\#517](https://github.com/transitland/transitland-datastore/pull/517) ([doublestranded](https://github.com/doublestranded))
- try \#2 on deprecating `operatedBy` and `servedBy` [\#513](https://github.com/transitland/transitland-datastore/pull/513) ([drewda](https://github.com/drewda))
- CSV Bulk Import [\#507](https://github.com/transitland/transitland-datastore/pull/507) ([irees](https://github.com/irees))
- No added stops to rsp geom [\#506](https://github.com/transitland/transitland-datastore/pull/506) ([doublestranded](https://github.com/doublestranded))
- Eval distances [\#505](https://github.com/transitland/transitland-datastore/pull/505) ([doublestranded](https://github.com/doublestranded))
- test metadata for CircleCI [\#504](https://github.com/transitland/transitland-datastore/pull/504) ([drewda](https://github.com/drewda))
- fix for: automatic fetch of newly created feeds fails [\#503](https://github.com/transitland/transitland-datastore/pull/503) ([drewda](https://github.com/drewda))
- production release 4.7.4 [\#502](https://github.com/transitland/transitland-datastore/pull/502) ([drewda](https://github.com/drewda))
- route `operatedBy` and stop `servedBy` query params should be under\_scored, rather than camelCased [\#495](https://github.com/transitland/transitland-datastore/pull/495) ([drewda](https://github.com/drewda))

## [4.7.4](https://github.com/transitland/transitland-datastore/tree/4.7.4) (2016-03-11)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.7.3...4.7.4)

**Fixed bugs:**

- FeedsController\#show should throw 404 when feed not found [\#500](https://github.com/transitland/transitland-datastore/issues/500)

**Closed issues:**

- GtfsGraph refactoring [\#288](https://github.com/transitland/transitland-datastore/issues/288)

**Merged pull requests:**

- FeedsController\#show should throw 404 when feed not found [\#501](https://github.com/transitland/transitland-datastore/pull/501) ([drewda](https://github.com/drewda))
- Bump gtfs gem; fixes process leak [\#499](https://github.com/transitland/transitland-datastore/pull/499) ([irees](https://github.com/irees))
- Upgrade to Rails 4.2.6 \(and update misc. gems\) [\#496](https://github.com/transitland/transitland-datastore/pull/496) ([drewda](https://github.com/drewda))
- production release 4.7.3 [\#494](https://github.com/transitland/transitland-datastore/pull/494) ([drewda](https://github.com/drewda))
- Feed info progress bar [\#480](https://github.com/transitland/transitland-datastore/pull/480) ([irees](https://github.com/irees))
- Changeset "as\_change" [\#301](https://github.com/transitland/transitland-datastore/pull/301) ([irees](https://github.com/irees))

## [4.7.3](https://github.com/transitland/transitland-datastore/tree/4.7.3) (2016-03-09)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.7.2...4.7.3)

**Closed issues:**

- FeedEater: Keep change payloads [\#493](https://github.com/transitland/transitland-datastore/issues/493)
- improve GeoJSON endpoints [\#398](https://github.com/transitland/transitland-datastore/issues/398)

**Merged pull requests:**

- FeedEater: Keep change payloads [\#491](https://github.com/transitland/transitland-datastore/pull/491) ([irees](https://github.com/irees))
- improve GeoJSON endpoints [\#489](https://github.com/transitland/transitland-datastore/pull/489) ([drewda](https://github.com/drewda))
- production release 4.7.2 [\#485](https://github.com/transitland/transitland-datastore/pull/485) ([drewda](https://github.com/drewda))

## [4.7.2](https://github.com/transitland/transitland-datastore/tree/4.7.2) (2016-03-08)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.7.1...4.7.2)

**Implemented enhancements:**

- Route color model attribute [\#468](https://github.com/transitland/transitland-datastore/issues/468)
- Add single logging metric for determining Valhalla import use [\#466](https://github.com/transitland/transitland-datastore/issues/466)

**Closed issues:**

- Unreferenced entity cleanup [\#473](https://github.com/transitland/transitland-datastore/issues/473)
- SSP controller: Allow multiple import\_level [\#465](https://github.com/transitland/transitland-datastore/issues/465)
- Feed serializer: add active\_feed\_version\_import\_level [\#461](https://github.com/transitland/transitland-datastore/issues/461)

**Merged pull requests:**

- Entity cleanup more logging [\#486](https://github.com/transitland/transitland-datastore/pull/486) ([doublestranded](https://github.com/doublestranded))
- update gems [\#484](https://github.com/transitland/transitland-datastore/pull/484) ([drewda](https://github.com/drewda))
- Rsp single metric log [\#483](https://github.com/transitland/transitland-datastore/pull/483) ([doublestranded](https://github.com/doublestranded))
- logging for equal consecutive distances and segment mismatch case [\#482](https://github.com/transitland/transitland-datastore/pull/482) ([doublestranded](https://github.com/doublestranded))
- Unreferenced entity cleanup [\#479](https://github.com/transitland/transitland-datastore/pull/479) ([doublestranded](https://github.com/doublestranded))
- Route color [\#478](https://github.com/transitland/transitland-datastore/pull/478) ([doublestranded](https://github.com/doublestranded))
- SSP controller: allow multiple import\_level's [\#467](https://github.com/transitland/transitland-datastore/pull/467) ([irees](https://github.com/irees))
- Update gems and upgrade to Rails 4.2.5.2 [\#462](https://github.com/transitland/transitland-datastore/pull/462) ([drewda](https://github.com/drewda))
- Production release 4.7.1 [\#460](https://github.com/transitland/transitland-datastore/pull/460) ([irees](https://github.com/irees))

## [4.7.1](https://github.com/transitland/transitland-datastore/tree/4.7.1) (2016-02-27)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.7.0...4.7.1)

**Merged pull requests:**

- SSP controller: pass new query params to prev/next links [\#459](https://github.com/transitland/transitland-datastore/pull/459) ([irees](https://github.com/irees))
- production release 4.7 [\#442](https://github.com/transitland/transitland-datastore/pull/442) ([drewda](https://github.com/drewda))

## [4.7.0](https://github.com/transitland/transitland-datastore/tree/4.7.0) (2016-02-26)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.6.0...4.7.0)

**Fixed bugs:**

- distance\_from\_segment failing, causing distance calculations to fail [\#449](https://github.com/transitland/transitland-datastore/issues/449)
- Null values for SSP distances [\#447](https://github.com/transitland/transitland-datastore/issues/447)
- Fix last stop distance calc edge case [\#435](https://github.com/transitland/transitland-datastore/issues/435)
- SSP where\_active bug fix: returned all active feeds, not feed versions [\#431](https://github.com/transitland/transitland-datastore/issues/431)
- Incorrect distances saved in SSP when stop is repeated [\#418](https://github.com/transitland/transitland-datastore/issues/418)

**Closed issues:**

- Disk space leaks [\#455](https://github.com/transitland/transitland-datastore/issues/455)
- FeedVersionImports should probably list more than 1 per page [\#453](https://github.com/transitland/transitland-datastore/issues/453)
- Add sortkey/sortorder to paginated controllers [\#440](https://github.com/transitland/transitland-datastore/issues/440)
- FeedEater: Delete any existing SSPs for FeedVersion before starting [\#429](https://github.com/transitland/transitland-datastore/issues/429)
- FeedVersionImport: include import\_level [\#428](https://github.com/transitland/transitland-datastore/issues/428)
- SSP controller: where\_active default scope [\#427](https://github.com/transitland/transitland-datastore/issues/427)
- Feed activation: do not delete old SSPs [\#426](https://github.com/transitland/transitland-datastore/issues/426)
- Some problems with API endpoint [\#416](https://github.com/transitland/transitland-datastore/issues/416)
- FeedVersion import\_level should be editable [\#397](https://github.com/transitland/transitland-datastore/issues/397)
- RSP followup improvements [\#336](https://github.com/transitland/transitland-datastore/issues/336)

**Merged pull requests:**

- FeedVersionImports PER\_PAGE [\#458](https://github.com/transitland/transitland-datastore/pull/458) ([irees](https://github.com/irees))
- Distance calculation remove dup sqrt [\#457](https://github.com/transitland/transitland-datastore/pull/457) ([doublestranded](https://github.com/doublestranded))
- Add controller sorting [\#454](https://github.com/transitland/transitland-datastore/pull/454) ([meghanhade](https://github.com/meghanhade))
- logging for number of stop times with shape\_dist\_traveled if present [\#452](https://github.com/transitland/transitland-datastore/pull/452) ([doublestranded](https://github.com/doublestranded))
- Create Feed Onestop ID using GTFS feed\_id [\#451](https://github.com/transitland/transitland-datastore/pull/451) ([irees](https://github.com/irees))
- failsafe distance\_to\_segment value 0 if precision mismatch [\#450](https://github.com/transitland/transitland-datastore/pull/450) ([doublestranded](https://github.com/doublestranded))
- line points are de-duplicated after stop points are added [\#448](https://github.com/transitland/transitland-datastore/pull/448) ([doublestranded](https://github.com/doublestranded))
- API updates for Dispatcher [\#443](https://github.com/transitland/transitland-datastore/pull/443) ([drewda](https://github.com/drewda))
- import\_level improvements [\#439](https://github.com/transitland/transitland-datastore/pull/439) ([irees](https://github.com/irees))
- Improved Feed Version activation & SSP cleanup [\#438](https://github.com/transitland/transitland-datastore/pull/438) ([irees](https://github.com/irees))
- Is modified for before after stops [\#437](https://github.com/transitland/transitland-datastore/pull/437) ([doublestranded](https://github.com/doublestranded))
- Fix rsp last stop distance calc [\#436](https://github.com/transitland/transitland-datastore/pull/436) ([doublestranded](https://github.com/doublestranded))
- SSP controller default scope and new query params [\#434](https://github.com/transitland/transitland-datastore/pull/434) ([irees](https://github.com/irees))
- Repeating stops distance calc fix [\#433](https://github.com/transitland/transitland-datastore/pull/433) ([doublestranded](https://github.com/doublestranded))
- SSP\#where\_active bug fix [\#432](https://github.com/transitland/transitland-datastore/pull/432) ([irees](https://github.com/irees))
- production release 4.6.0 [\#425](https://github.com/transitland/transitland-datastore/pull/425) ([drewda](https://github.com/drewda))
- added rsp logging line in load\_tl\_route\_stop\_patterns [\#424](https://github.com/transitland/transitland-datastore/pull/424) ([doublestranded](https://github.com/doublestranded))
- update gems [\#423](https://github.com/transitland/transitland-datastore/pull/423) ([drewda](https://github.com/drewda))
- Rsp followup improvements [\#413](https://github.com/transitland/transitland-datastore/pull/413) ([doublestranded](https://github.com/doublestranded))

## [4.6.0](https://github.com/transitland/transitland-datastore/tree/4.6.0) (2016-02-18)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.5.1...4.6.0)

**Fixed bugs:**

- Convert email address to all lowercase [\#419](https://github.com/transitland/transitland-datastore/issues/419)
- FeedFetch and FeedInfo services aren't handling GTFS archives hosted on GitHub [\#407](https://github.com/transitland/transitland-datastore/issues/407)

**Closed issues:**

- create SSPs directly in FeedEaterScheduleWorker + activate a feed version by import\_level in FeedActivationWorker [\#392](https://github.com/transitland/transitland-datastore/issues/392)
- SSP Bulk Import [\#319](https://github.com/transitland/transitland-datastore/issues/319)

**Merged pull requests:**

- Convert email address to all lowercase [\#422](https://github.com/transitland/transitland-datastore/pull/422) ([drewda](https://github.com/drewda))
- Fix FeedFetch: Operator has no stops [\#421](https://github.com/transitland/transitland-datastore/pull/421) ([irees](https://github.com/irees))
- FeedFetch HTTPS [\#420](https://github.com/transitland/transitland-datastore/pull/420) ([irees](https://github.com/irees))
- Rsp documentation [\#414](https://github.com/transitland/transitland-datastore/pull/414) ([doublestranded](https://github.com/doublestranded))
- updating change log for 4.5.0 and 4.5.1 [\#412](https://github.com/transitland/transitland-datastore/pull/412) ([drewda](https://github.com/drewda))
- ScheduleStopPair Direct Import [\#277](https://github.com/transitland/transitland-datastore/pull/277) ([drewda](https://github.com/drewda))

## [4.5.1](https://github.com/transitland/transitland-datastore/tree/4.5.1) (2016-02-12)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.5.0...4.5.1)

**Fixed bugs:**

- fix RouteStopPatternController\#show [\#390](https://github.com/transitland/transitland-datastore/issues/390)

**Closed issues:**

- FeedActivationWorker [\#406](https://github.com/transitland/transitland-datastore/issues/406)
- Issue adding SEPTA GTFS file on https://transit.land/feed-registry/feeds/new [\#405](https://github.com/transitland/transitland-datastore/issues/405)
- RoutesController\#index and ScheduleStopPairController\#index should include `route\_stop\_patterns` in query [\#391](https://github.com/transitland/transitland-datastore/issues/391)
- RouteStopPatterns \(and improved route geometries\) [\#279](https://github.com/transitland/transitland-datastore/issues/279)

**Merged pull requests:**

- production release 4.5.1 [\#410](https://github.com/transitland/transitland-datastore/pull/410) ([drewda](https://github.com/drewda))
- adding more information to CONTRIBUTING.md [\#409](https://github.com/transitland/transitland-datastore/pull/409) ([drewda](https://github.com/drewda))
- update gems [\#403](https://github.com/transitland/transitland-datastore/pull/403) ([drewda](https://github.com/drewda))
- update annotations [\#402](https://github.com/transitland/transitland-datastore/pull/402) ([drewda](https://github.com/drewda))
- Feed Activation Worker [\#396](https://github.com/transitland/transitland-datastore/pull/396) ([irees](https://github.com/irees))
- Route stop pattern controller updates [\#394](https://github.com/transitland/transitland-datastore/pull/394) ([doublestranded](https://github.com/doublestranded))
- fix to RouteStopPattern show [\#393](https://github.com/transitland/transitland-datastore/pull/393) ([doublestranded](https://github.com/doublestranded))

## [4.5.0](https://github.com/transitland/transitland-datastore/tree/4.5.0) (2016-02-09)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.4.2...4.5.0)

**Fixed bugs:**

- admin reset isn't clearing out `User`s [\#386](https://github.com/transitland/transitland-datastore/issues/386)
- Rework RouteStopPattern.find\_rsp, mesh better with gtfs\_graph search/caching [\#380](https://github.com/transitland/transitland-datastore/issues/380)
- Changeset::Error PG::ProgramLimitExceeded: ERROR:  index row size 3304 exceeds maximum 2712 for index "index\_current\_route\_stop\_patterns\_on\_trips" [\#373](https://github.com/transitland/transitland-datastore/issues/373)
- Exit feed import if no agency\_id referenced operators found in feed [\#356](https://github.com/transitland/transitland-datastore/issues/356)
- Changeset::Error: PG::ProgramLimitExceeded: ERROR:  index row size 2944 exceeds maximum 2712 for index "index\_current\_route\_stop\_patterns\_on\_identifiers" [\#355](https://github.com/transitland/transitland-datastore/issues/355)
- wrong e-mail notifications are going out [\#347](https://github.com/transitland/transitland-datastore/issues/347)
- staging can't send e-mail notifications through Mandrill [\#345](https://github.com/transitland/transitland-datastore/issues/345)
- Fix Schedule Stop Pairs by Route Stop Pattern query [\#341](https://github.com/transitland/transitland-datastore/issues/341)
- Fix RSP Geometry distance calculation for stops outside [\#337](https://github.com/transitland/transitland-datastore/issues/337)
- `has\_a\_onestop\_id\_spec` sometimes fails based on `ActiveRecord::Relation` order [\#389](https://github.com/transitland/transitland-datastore/pull/389) ([drewda](https://github.com/drewda))

**Closed issues:**

- `has\_a\_onestop\_id\_spec` sometimes fails based on `ActiveRecord::Relation` order [\#388](https://github.com/transitland/transitland-datastore/issues/388)
- Missing Route geometries generated from RSPs [\#384](https://github.com/transitland/transitland-datastore/issues/384)
- Handle null gtfsAgencyId [\#374](https://github.com/transitland/transitland-datastore/issues/374)
- Don't delete ChangePayloads by default [\#370](https://github.com/transitland/transitland-datastore/issues/370)
- increase FeedInfo cache expiration \(and make it configurable by env variables\) [\#367](https://github.com/transitland/transitland-datastore/issues/367)
- Caltrain agency\_id [\#364](https://github.com/transitland/transitland-datastore/issues/364)
- Remove duplicate RSP trips [\#361](https://github.com/transitland/transitland-datastore/issues/361)
- Partial Station Hierarchy [\#360](https://github.com/transitland/transitland-datastore/issues/360)
- FeedInfo return remote request response code if exception [\#358](https://github.com/transitland/transitland-datastore/issues/358)
- when a new `Feed` has been created, automatically enqueue its first fetch [\#353](https://github.com/transitland/transitland-datastore/issues/353)
- validate that `User.email` is actually an e-mail address [\#349](https://github.com/transitland/transitland-datastore/issues/349)
- RSPs should only be created from trips actually used by routes associated with found operators [\#344](https://github.com/transitland/transitland-datastore/issues/344)
- Correctly fall back on missing shapes.txt [\#339](https://github.com/transitland/transitland-datastore/issues/339)
- Changeset Entity Imported From Feed [\#338](https://github.com/transitland/transitland-datastore/issues/338)
- Send an email when feed is imported and ready to go \(or fails\) [\#326](https://github.com/transitland/transitland-datastore/issues/326)
- Send an email when a user submits a feed [\#325](https://github.com/transitland/transitland-datastore/issues/325)
- enqueue a feed fetch after changeset application creates a new feed model [\#320](https://github.com/transitland/transitland-datastore/issues/320)
- handle GTFS feeds with `calendar\_dates.txt` but no `calendars.txt` [\#308](https://github.com/transitland/transitland-datastore/issues/308)
- send confirmation e-mail to User after they submit a changeset and after changeset is applied [\#281](https://github.com/transitland/transitland-datastore/issues/281)
- add User data model and associate with Changesets [\#258](https://github.com/transitland/transitland-datastore/issues/258)
- add Relation and RelationMember [\#17](https://github.com/transitland/transitland-datastore/issues/17)

**Merged pull requests:**

- admin reset isn't clearing out `User`s [\#387](https://github.com/transitland/transitland-datastore/pull/387) ([drewda](https://github.com/drewda))
- Fix Route geometry generated from RSPs [\#385](https://github.com/transitland/transitland-datastore/pull/385) ([irees](https://github.com/irees))
- update error messages [\#383](https://github.com/transitland/transitland-datastore/pull/383) ([meghanhade](https://github.com/meghanhade))
- Updated route stop pattern distances [\#382](https://github.com/transitland/transitland-datastore/pull/382) ([doublestranded](https://github.com/doublestranded))
- Find rsp refactor [\#381](https://github.com/transitland/transitland-datastore/pull/381) ([doublestranded](https://github.com/doublestranded))
- Preserve ChangePayloads by default [\#379](https://github.com/transitland/transitland-datastore/pull/379) ([irees](https://github.com/irees))
- Fix case where Feed.operators\_in\_feed gtfs\_agency\_id is nil [\#378](https://github.com/transitland/transitland-datastore/pull/378) ([irees](https://github.com/irees))
- Fetch and create FeedVersion when a new Feed is created [\#376](https://github.com/transitland/transitland-datastore/pull/376) ([irees](https://github.com/irees))
- Switch index type rsp trips [\#375](https://github.com/transitland/transitland-datastore/pull/375) ([doublestranded](https://github.com/doublestranded))
- production release 4.5 [\#372](https://github.com/transitland/transitland-datastore/pull/372) ([drewda](https://github.com/drewda))
- improve changeset notes [\#371](https://github.com/transitland/transitland-datastore/pull/371) ([drewda](https://github.com/drewda))
- Partial Station Hierarchy [\#369](https://github.com/transitland/transitland-datastore/pull/369) ([irees](https://github.com/irees))
- Increase FeedInfo cache expiration time and read from config [\#368](https://github.com/transitland/transitland-datastore/pull/368) ([irees](https://github.com/irees))
- Fix\#355 [\#366](https://github.com/transitland/transitland-datastore/pull/366) ([doublestranded](https://github.com/doublestranded))
- Update Caltrain sample feed gtfsAgencyId to 'CT' [\#365](https://github.com/transitland/transitland-datastore/pull/365) ([irees](https://github.com/irees))
- Remove duplicate RSP trips [\#363](https://github.com/transitland/transitland-datastore/pull/363) ([doublestranded](https://github.com/doublestranded))
- Failed FeedInfo should return request http response code in error [\#359](https://github.com/transitland/transitland-datastore/pull/359) ([irees](https://github.com/irees))
- Fix missing operator in feed [\#357](https://github.com/transitland/transitland-datastore/pull/357) ([irees](https://github.com/irees))
- Handle EntitiesImportedFromFeed relations in Changeset apply [\#354](https://github.com/transitland/transitland-datastore/pull/354) ([irees](https://github.com/irees))
- validate that `User.email` is actually an e-mail address [\#350](https://github.com/transitland/transitland-datastore/pull/350) ([drewda](https://github.com/drewda))
- putting the right e-mail notifications in the right places [\#348](https://github.com/transitland/transitland-datastore/pull/348) ([drewda](https://github.com/drewda))
- fixing SMTP/Mandrill configuration [\#346](https://github.com/transitland/transitland-datastore/pull/346) ([drewda](https://github.com/drewda))
- user controller now allows editing of all fields [\#343](https://github.com/transitland/transitland-datastore/pull/343) ([drewda](https://github.com/drewda))
- closes \#341 [\#342](https://github.com/transitland/transitland-datastore/pull/342) ([doublestranded](https://github.com/doublestranded))
- Update gtfs gem & resolve shape/calendar issues [\#340](https://github.com/transitland/transitland-datastore/pull/340) ([irees](https://github.com/irees))
- production release 4.4.2 [\#334](https://github.com/transitland/transitland-datastore/pull/334) ([drewda](https://github.com/drewda))
- add User model, associate with Changesets, set up e-mail notifications [\#304](https://github.com/transitland/transitland-datastore/pull/304) ([drewda](https://github.com/drewda))
- Route stop pattern [\#249](https://github.com/transitland/transitland-datastore/pull/249) ([doublestranded](https://github.com/doublestranded))

## [4.4.2](https://github.com/transitland/transitland-datastore/tree/4.4.2) (2016-01-26)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.4.1...4.4.2)

**Fixed bugs:**

- FeedFetcher \(or FeedInfo?\) worker may still be leaving behind temp files [\#311](https://github.com/transitland/transitland-datastore/issues/311)
- operator re-imported from multiple feed versions lists duplicate imported\_from\_feed\_onestop\_ids [\#302](https://github.com/transitland/transitland-datastore/issues/302)

**Closed issues:**

- SSP API: Raise error if missing Stop/Operator/Route [\#330](https://github.com/transitland/transitland-datastore/issues/330)
- Fix SSP controller operator\_onestop\_id [\#327](https://github.com/transitland/transitland-datastore/issues/327)
- if FeedFetcher has an exception, log the error [\#321](https://github.com/transitland/transitland-datastore/issues/321)
- FeedInfo better error messages for bad GTFS feeds [\#317](https://github.com/transitland/transitland-datastore/issues/317)
- ScheduleStopPair `service\_to\_date` scope + query parameter [\#309](https://github.com/transitland/transitland-datastore/issues/309)
- add changelog [\#299](https://github.com/transitland/transitland-datastore/issues/299)
- test Rubocop and HoundCI for style checking [\#297](https://github.com/transitland/transitland-datastore/issues/297)
- refactor Onestop ID class [\#287](https://github.com/transitland/transitland-datastore/issues/287)
- remove Changeset append API endpoint [\#271](https://github.com/transitland/transitland-datastore/issues/271)

**Merged pull requests:**

- Rails 4.2.5.1 and misc. gem updates [\#335](https://github.com/transitland/transitland-datastore/pull/335) ([drewda](https://github.com/drewda))
- SSP where\_service\_before\_date [\#333](https://github.com/transitland/transitland-datastore/pull/333) ([irees](https://github.com/irees))
- Add find\_by\_onestop\_ids, find\_by\_onestop\_ids! methods [\#331](https://github.com/transitland/transitland-datastore/pull/331) ([irees](https://github.com/irees))
- turning FeedInfo service's download methods into a new FeedFetch service [\#329](https://github.com/transitland/transitland-datastore/pull/329) ([drewda](https://github.com/drewda))
- Fix SSP controller operator\_onestop\_id [\#328](https://github.com/transitland/transitland-datastore/pull/328) ([irees](https://github.com/irees))
- Remove changeset append [\#324](https://github.com/transitland/transitland-datastore/pull/324) ([irees](https://github.com/irees))
- Improve feed info error handling [\#323](https://github.com/transitland/transitland-datastore/pull/323) ([irees](https://github.com/irees))
- if FeedFetcher has an exception, log the error [\#322](https://github.com/transitland/transitland-datastore/pull/322) ([drewda](https://github.com/drewda))
- Changeset/ChangePayload deletes [\#315](https://github.com/transitland/transitland-datastore/pull/315) ([drewda](https://github.com/drewda))
- allow user to fetch the latest version of one feed [\#314](https://github.com/transitland/transitland-datastore/pull/314) ([drewda](https://github.com/drewda))
- Gem updates [\#313](https://github.com/transitland/transitland-datastore/pull/313) ([drewda](https://github.com/drewda))
- trying agin to fix custom HoundCI config [\#307](https://github.com/transitland/transitland-datastore/pull/307) ([drewda](https://github.com/drewda))
- fix custom HoundCI config [\#306](https://github.com/transitland/transitland-datastore/pull/306) ([drewda](https://github.com/drewda))
- Major refactoring of OnestopId: [\#305](https://github.com/transitland/transitland-datastore/pull/305) ([doublestranded](https://github.com/doublestranded))
- fix for: operator re-imported from multiple feed versions lists duplicate `imported\_from\_feed\_onestop\_ids` [\#303](https://github.com/transitland/transitland-datastore/pull/303) ([drewda](https://github.com/drewda))
- adding CHANGELOG [\#300](https://github.com/transitland/transitland-datastore/pull/300) ([drewda](https://github.com/drewda))
- Rubocop and HoundCI style checking [\#298](https://github.com/transitland/transitland-datastore/pull/298) ([drewda](https://github.com/drewda))

## [4.4.1](https://github.com/transitland/transitland-datastore/tree/4.4.1) (2016-01-07)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.4.0...4.4.1)

**Fixed bugs:**

- Sidekiq process failing when some FeedEaterScheduleWorker jobs consume too much memory [\#291](https://github.com/transitland/transitland-datastore/issues/291)

**Merged pull requests:**

- updating ActiveModelSerializers [\#296](https://github.com/transitland/transitland-datastore/pull/296) ([drewda](https://github.com/drewda))
- reduce staging log level [\#295](https://github.com/transitland/transitland-datastore/pull/295) ([drewda](https://github.com/drewda))
- production release 4.4.1 [\#294](https://github.com/transitland/transitland-datastore/pull/294) ([drewda](https://github.com/drewda))
- update gems [\#293](https://github.com/transitland/transitland-datastore/pull/293) ([drewda](https://github.com/drewda))
- improve Sidekiq background job stability [\#292](https://github.com/transitland/transitland-datastore/pull/292) ([drewda](https://github.com/drewda))
- update gems [\#289](https://github.com/transitland/transitland-datastore/pull/289) ([drewda](https://github.com/drewda))
- update misc. gems [\#270](https://github.com/transitland/transitland-datastore/pull/270) ([drewda](https://github.com/drewda))

## [4.4.0](https://github.com/transitland/transitland-datastore/tree/4.4.0) (2015-12-23)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.3.2...4.4.0)

**Fixed bugs:**

- FeedVersion attachment temp files are lingering on worker servers [\#264](https://github.com/transitland/transitland-datastore/issues/264)

**Closed issues:**

- add vehicle\_type index to Route tables [\#268](https://github.com/transitland/transitland-datastore/issues/268)
- store vehicle type as integer on Route model [\#266](https://github.com/transitland/transitland-datastore/issues/266)
- allow SSP queries by multiple Onestop IDs [\#262](https://github.com/transitland/transitland-datastore/issues/262)
- format logs for Logstash/Kibana [\#254](https://github.com/transitland/transitland-datastore/issues/254)
- Add location\_type to API [\#246](https://github.com/transitland/transitland-datastore/issues/246)

**Merged pull requests:**

- add vehicle\_type index to Route tables [\#269](https://github.com/transitland/transitland-datastore/pull/269) ([drewda](https://github.com/drewda))
- store vehicle type as integer attribute on Route model [\#267](https://github.com/transitland/transitland-datastore/pull/267) ([drewda](https://github.com/drewda))
- fix for: FeedVersion attachment temp files are lingering on worker servers [\#265](https://github.com/transitland/transitland-datastore/pull/265) ([drewda](https://github.com/drewda))
- SSP API endpoint allows queries by multiple Onestop IDs [\#263](https://github.com/transitland/transitland-datastore/pull/263) ([drewda](https://github.com/drewda))
- production release 4.4.0 [\#261](https://github.com/transitland/transitland-datastore/pull/261) ([drewda](https://github.com/drewda))
- Use OJ for JSON serialization [\#259](https://github.com/transitland/transitland-datastore/pull/259) ([drewda](https://github.com/drewda))
- Logstash logs [\#255](https://github.com/transitland/transitland-datastore/pull/255) ([drewda](https://github.com/drewda))
- New route types [\#253](https://github.com/transitland/transitland-datastore/pull/253) ([doublestranded](https://github.com/doublestranded))

## [4.3.2](https://github.com/transitland/transitland-datastore/tree/4.3.2) (2015-12-18)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.3.1...4.3.2)

**Merged pull requests:**

- updating gems [\#252](https://github.com/transitland/transitland-datastore/pull/252) ([drewda](https://github.com/drewda))
- production release 4.3.2 [\#251](https://github.com/transitland/transitland-datastore/pull/251) ([drewda](https://github.com/drewda))
- reducing Sidekiq concurrency on prod [\#250](https://github.com/transitland/transitland-datastore/pull/250) ([drewda](https://github.com/drewda))
- adds very basic dockerfile [\#248](https://github.com/transitland/transitland-datastore/pull/248) ([baldur](https://github.com/baldur))
- upgrade rgeo and rgeo-geojson [\#247](https://github.com/transitland/transitland-datastore/pull/247) ([drewda](https://github.com/drewda))
- FeedInfo response 500 on errors [\#245](https://github.com/transitland/transitland-datastore/pull/245) ([irees](https://github.com/irees))
- Remove unnecessary Tempfile.new 'wb' flag. [\#244](https://github.com/transitland/transitland-datastore/pull/244) ([irees](https://github.com/irees))
- Change payload edit [\#243](https://github.com/transitland/transitland-datastore/pull/243) ([irees](https://github.com/irees))
- Feed fetch info [\#242](https://github.com/transitland/transitland-datastore/pull/242) ([irees](https://github.com/irees))

## [4.3.1](https://github.com/transitland/transitland-datastore/tree/4.3.1) (2015-12-02)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.3.0...4.3.1)

**Merged pull requests:**

- production release 4.3.1 [\#241](https://github.com/transitland/transitland-datastore/pull/241) ([drewda](https://github.com/drewda))
- only include pagination total if `?total=true` [\#240](https://github.com/transitland/transitland-datastore/pull/240) ([drewda](https://github.com/drewda))
- Bump gtfs rc7 [\#239](https://github.com/transitland/transitland-datastore/pull/239) ([irees](https://github.com/irees))
- Admin additions: PgHero for database analysis and styling improvements [\#238](https://github.com/transitland/transitland-datastore/pull/238) ([drewda](https://github.com/drewda))
- remove outdated references to old Feed Registry [\#237](https://github.com/transitland/transitland-datastore/pull/237) ([drewda](https://github.com/drewda))
- Remove partially-enforced Change Payload uniqueness constraint [\#236](https://github.com/transitland/transitland-datastore/pull/236) ([irees](https://github.com/irees))
- Pagination refactor [\#235](https://github.com/transitland/transitland-datastore/pull/235) ([irees](https://github.com/irees))
- dependency updates \(including Rails 4.2.5 and Sidekiq 4.0\) [\#234](https://github.com/transitland/transitland-datastore/pull/234) ([drewda](https://github.com/drewda))
- Stop conflation logger [\#233](https://github.com/transitland/transitland-datastore/pull/233) ([doublestranded](https://github.com/doublestranded))
- Updated to match blog post [\#232](https://github.com/transitland/transitland-datastore/pull/232) ([irees](https://github.com/irees))
- Routes by stops bounding box [\#231](https://github.com/transitland/transitland-datastore/pull/231) ([doublestranded](https://github.com/doublestranded))
- upgrade to Ruby 2.2.3 [\#187](https://github.com/transitland/transitland-datastore/pull/187) ([drewda](https://github.com/drewda))

## [4.3.0](https://github.com/transitland/transitland-datastore/tree/4.3.0) (2015-11-12)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.2.0...4.3.0)

**Merged pull requests:**

- production release 4.3.0 [\#230](https://github.com/transitland/transitland-datastore/pull/230) ([drewda](https://github.com/drewda))
- trying to fix crontab again [\#229](https://github.com/transitland/transitland-datastore/pull/229) ([drewda](https://github.com/drewda))
- SSP documentation updates [\#228](https://github.com/transitland/transitland-datastore/pull/228) ([irees](https://github.com/irees))
- Activate/deactive SSPs [\#226](https://github.com/transitland/transitland-datastore/pull/226) ([irees](https://github.com/irees))
- reduce Sidekiq concurrency on dev stack [\#225](https://github.com/transitland/transitland-datastore/pull/225) ([drewda](https://github.com/drewda))
- add indices on geometry columns [\#224](https://github.com/transitland/transitland-datastore/pull/224) ([drewda](https://github.com/drewda))
- fixing crontab on servers [\#223](https://github.com/transitland/transitland-datastore/pull/223) ([drewda](https://github.com/drewda))
- Auto conflating stops [\#222](https://github.com/transitland/transitland-datastore/pull/222) ([doublestranded](https://github.com/doublestranded))
- Fix BART initial convex hull [\#219](https://github.com/transitland/transitland-datastore/pull/219) ([irees](https://github.com/irees))
- Improve SSP performance by caching entity lookups [\#218](https://github.com/transitland/transitland-datastore/pull/218) ([irees](https://github.com/irees))
- Making tmp directory if not exists [\#217](https://github.com/transitland/transitland-datastore/pull/217) ([doublestranded](https://github.com/doublestranded))
- Update to sidekiq-unique-job broke unique: true [\#216](https://github.com/transitland/transitland-datastore/pull/216) ([irees](https://github.com/irees))

## [4.2.0](https://github.com/transitland/transitland-datastore/tree/4.2.0) (2015-11-04)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.1.1...4.2.0)

**Closed issues:**

- meta\["next"\] does echo all initial parameters [\#205](https://github.com/transitland/transitland-datastore/issues/205)

**Merged pull requests:**

- production release 4.2.0 [\#215](https://github.com/transitland/transitland-datastore/pull/215) ([drewda](https://github.com/drewda))
- Assorted code clean-up and maintenance [\#214](https://github.com/transitland/transitland-datastore/pull/214) ([drewda](https://github.com/drewda))
- Include origin\_departure\_between, operator\_onestop\_id, and trip in SSP pagination [\#213](https://github.com/transitland/transitland-datastore/pull/213) ([irees](https://github.com/irees))
- display most recent FeedVersionImport first [\#212](https://github.com/transitland/transitland-datastore/pull/212) ([drewda](https://github.com/drewda))
- Log ChangePayload failures and payloads [\#211](https://github.com/transitland/transitland-datastore/pull/211) ([irees](https://github.com/irees))
- add attribution text to Feed data model [\#210](https://github.com/transitland/transitland-datastore/pull/210) ([meghanhade](https://github.com/meghanhade))
- SSP accessibility labels [\#209](https://github.com/transitland/transitland-datastore/pull/209) ([irees](https://github.com/irees))
- Update ACTransit GTFS url [\#208](https://github.com/transitland/transitland-datastore/pull/208) ([irees](https://github.com/irees))
- Fallback order before pagination [\#207](https://github.com/transitland/transitland-datastore/pull/207) ([irees](https://github.com/irees))
- Bump GTFS lib to fix issue with VTA \(bad service\_days\_of\_week\) [\#206](https://github.com/transitland/transitland-datastore/pull/206) ([irees](https://github.com/irees))
- ScheduleStopPair controller origin\_departure\_between [\#204](https://github.com/transitland/transitland-datastore/pull/204) ([irees](https://github.com/irees))
- remove n+1 queries found using bullet gem [\#203](https://github.com/transitland/transitland-datastore/pull/203) ([drewda](https://github.com/drewda))
- Fix routes serving stops [\#202](https://github.com/transitland/transitland-datastore/pull/202) ([irees](https://github.com/irees))
- SSP JSON Schema fixes [\#201](https://github.com/transitland/transitland-datastore/pull/201) ([irees](https://github.com/irees))
- one FeedEaterScheduleWorker per Sidekiq process [\#200](https://github.com/transitland/transitland-datastore/pull/200) ([drewda](https://github.com/drewda))
- Don't add Operators to SSPs during migration [\#199](https://github.com/transitland/transitland-datastore/pull/199) ([irees](https://github.com/irees))
- JSON Schema for SSPs [\#198](https://github.com/transitland/transitland-datastore/pull/198) ([irees](https://github.com/irees))
- ScheduleStopPair add Operator and additional controller search parameters [\#196](https://github.com/transitland/transitland-datastore/pull/196) ([irees](https://github.com/irees))
- production release 4.1.1 [\#195](https://github.com/transitland/transitland-datastore/pull/195) ([drewda](https://github.com/drewda))
- Feedeater parallel schedule import [\#194](https://github.com/transitland/transitland-datastore/pull/194) ([irees](https://github.com/irees))
- Feed versions [\#141](https://github.com/transitland/transitland-datastore/pull/141) ([drewda](https://github.com/drewda))

## [4.1.1](https://github.com/transitland/transitland-datastore/tree/4.1.1) (2015-10-07)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.1.0...4.1.1)

**Merged pull requests:**

- updating temporary feed info [\#193](https://github.com/transitland/transitland-datastore/pull/193) ([drewda](https://github.com/drewda))
- cosmetic updates for locate service changes [\#191](https://github.com/transitland/transitland-datastore/pull/191) ([kevinkreiser](https://github.com/kevinkreiser))

## [4.1.0](https://github.com/transitland/transitland-datastore/tree/4.1.0) (2015-10-02)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.1.0.rc1...4.1.0)

**Merged pull requests:**

- Feed update bbox [\#192](https://github.com/transitland/transitland-datastore/pull/192) ([irees](https://github.com/irees))
- route changeset callbacks conflicting [\#190](https://github.com/transitland/transitland-datastore/pull/190) ([drewda](https://github.com/drewda))

## [4.1.0.rc1](https://github.com/transitland/transitland-datastore/tree/4.1.0.rc1) (2015-10-01)
[Full Changelog](https://github.com/transitland/transitland-datastore/compare/4.0.0...4.1.0.rc1)

**Closed issues:**

- API gives same results for different queries [\#164](https://github.com/transitland/transitland-datastore/issues/164)

**Merged pull requests:**

- upgrade Celluloid dependency [\#189](https://github.com/transitland/transitland-datastore/pull/189) ([drewda](https://github.com/drewda))
- Schedule stop pair interpolation [\#188](https://github.com/transitland/transitland-datastore/pull/188) ([irees](https://github.com/irees))
- DatastoreAdmin clears out OperatorInFeed tables [\#186](https://github.com/transitland/transitland-datastore/pull/186) ([drewda](https://github.com/drewda))
- Fix missing route shapes [\#185](https://github.com/transitland/transitland-datastore/pull/185) ([irees](https://github.com/irees))
- feed bounding box [\#184](https://github.com/transitland/transitland-datastore/pull/184) ([drewda](https://github.com/drewda))
- only one FeedEaterFeedWorker at a time [\#183](https://github.com/transitland/transitland-datastore/pull/183) ([drewda](https://github.com/drewda))
- conflate up to 100 stops in each Tyr request [\#182](https://github.com/transitland/transitland-datastore/pull/182) ([drewda](https://github.com/drewda))
- Rails 4.2.4 and gem upgrades [\#181](https://github.com/transitland/transitland-datastore/pull/181) ([drewda](https://github.com/drewda))
- Fix admin reset [\#180](https://github.com/transitland/transitland-datastore/pull/180) ([drewda](https://github.com/drewda))
- Refactor GTFS [\#179](https://github.com/transitland/transitland-datastore/pull/179) ([irees](https://github.com/irees))
- upgrade Google transitfeed validator [\#178](https://github.com/transitland/transitland-datastore/pull/178) ([drewda](https://github.com/drewda))
- Ruby-based FeedEater pipeline \(v4.0.0\) to production [\#177](https://github.com/transitland/transitland-datastore/pull/177) ([drewda](https://github.com/drewda))
- move Feed Registry from GitHub into Datastore [\#168](https://github.com/transitland/transitland-datastore/pull/168) ([drewda](https://github.com/drewda))

## [4.0.0](https://github.com/transitland/transitland-datastore/tree/4.0.0) (2015-09-21)
**Closed issues:**

- Invalid gemspec [\#128](https://github.com/transitland/transitland-datastore/issues/128)
- searching by OnestopID should be case insensitive [\#23](https://github.com/transitland/transitland-datastore/issues/23)
- apply/revert Changeset's [\#21](https://github.com/transitland/transitland-datastore/issues/21)
- have Rails seeds automatically import the two included GTFS feeds \(SFMTA and VTA\) [\#18](https://github.com/transitland/transitland-datastore/issues/18)
- add Operator and OperatorServingStop [\#16](https://github.com/transitland/transitland-datastore/issues/16)
- when importing from GTFS zips, create StopIdentifier's [\#15](https://github.com/transitland/transitland-datastore/issues/15)
- basic Changeset data model [\#13](https://github.com/transitland/transitland-datastore/issues/13)
- automatically generate and assign Onestop IDs [\#11](https://github.com/transitland/transitland-datastore/issues/11)
- serve stops as GeoJSON \(for slippy map consumption\) [\#10](https://github.com/transitland/transitland-datastore/issues/10)
- deploying: precompile assets [\#6](https://github.com/transitland/transitland-datastore/issues/6)
- deploying: run migrations [\#5](https://github.com/transitland/transitland-datastore/issues/5)
- import stops from GTFS zip [\#4](https://github.com/transitland/transitland-datastore/issues/4)

**Merged pull requests:**

- Feedeater integration tests [\#176](https://github.com/transitland/transitland-datastore/pull/176) ([irees](https://github.com/irees))
- "identifier" is misspelled in some places [\#175](https://github.com/transitland/transitland-datastore/pull/175) ([drewda](https://github.com/drewda))
- fix for: message on Changeset::Error hasn't been getting logged by FeedEater [\#174](https://github.com/transitland/transitland-datastore/pull/174) ([drewda](https://github.com/drewda))
- GTFS wrapper fix for PANYNJ PATH [\#173](https://github.com/transitland/transitland-datastore/pull/173) ([irees](https://github.com/irees))
- Correctly attach import\_log during exceptions [\#172](https://github.com/transitland/transitland-datastore/pull/172) ([irees](https://github.com/irees))
- FeedEater: add website to Operator [\#171](https://github.com/transitland/transitland-datastore/pull/171) ([irees](https://github.com/irees))
- Include timezones in Operator and Stop changesets. [\#170](https://github.com/transitland/transitland-datastore/pull/170) ([irees](https://github.com/irees))
- Feedimport add exception log [\#169](https://github.com/transitland/transitland-datastore/pull/169) ([irees](https://github.com/irees))
- Correctly calculate min/max service range from service\_added\_dates/service\_except\_dates [\#167](https://github.com/transitland/transitland-datastore/pull/167) ([irees](https://github.com/irees))
- limit Sidekiq to 10 concurrent jobs on staging and prod [\#166](https://github.com/transitland/transitland-datastore/pull/166) ([drewda](https://github.com/drewda))
- FeedEater remove python & improved FeedEater logging [\#165](https://github.com/transitland/transitland-datastore/pull/165) ([irees](https://github.com/irees))
- Feedeater filter service exceptions [\#163](https://github.com/transitland/transitland-datastore/pull/163) ([irees](https://github.com/irees))
- Use Addressable::Template to properly URL encode GTFS ID's [\#162](https://github.com/transitland/transitland-datastore/pull/162) ([irees](https://github.com/irees))
- Duplicate entity feeds [\#161](https://github.com/transitland/transitland-datastore/pull/161) ([irees](https://github.com/irees))
- FeedEater performance and bug fixes [\#160](https://github.com/transitland/transitland-datastore/pull/160) ([irees](https://github.com/irees))
- Feedeater fix schedule start date unset [\#159](https://github.com/transitland/transitland-datastore/pull/159) ([irees](https://github.com/irees))
- fix for: bbox query for stops returning errant results [\#158](https://github.com/transitland/transitland-datastore/pull/158) ([drewda](https://github.com/drewda))
- Add pry-rescue dependency [\#157](https://github.com/transitland/transitland-datastore/pull/157) ([irees](https://github.com/irees))
- Handle references to non-existent parent\_station [\#156](https://github.com/transitland/transitland-datastore/pull/156) ([irees](https://github.com/irees))
- Fix bug in GeohashHelpers.adjacent [\#155](https://github.com/transitland/transitland-datastore/pull/155) ([irees](https://github.com/irees))
- More carefully check and convert start\_date [\#154](https://github.com/transitland/transitland-datastore/pull/154) ([irees](https://github.com/irees))
- copy in license info from Feed Registry [\#153](https://github.com/transitland/transitland-datastore/pull/153) ([drewda](https://github.com/drewda))
- Onestop ID Creation [\#152](https://github.com/transitland/transitland-datastore/pull/152) ([irees](https://github.com/irees))
- entities can be from multiple feeds [\#151](https://github.com/transitland/transitland-datastore/pull/151) ([drewda](https://github.com/drewda))
- Truncate schedule\_stop\_pairs [\#150](https://github.com/transitland/transitland-datastore/pull/150) ([irees](https://github.com/irees))
- FeedEater Improvements for NYC MTA Convex Hull, MTA subway empty routes, VTA calendar dates, import levels [\#149](https://github.com/transitland/transitland-datastore/pull/149) ([irees](https://github.com/irees))
- fixing a temporary Gemfile issue [\#148](https://github.com/transitland/transitland-datastore/pull/148) ([drewda](https://github.com/drewda))
- Bug fix to trip\_chunks. Skip empty routes. [\#147](https://github.com/transitland/transitland-datastore/pull/147) ([irees](https://github.com/irees))
- associate entities \(Operator, Route, Stop\) and ScheduleStopPairs with Feed [\#146](https://github.com/transitland/transitland-datastore/pull/146) ([drewda](https://github.com/drewda))
- Feedeater ruby [\#145](https://github.com/transitland/transitland-datastore/pull/145) ([irees](https://github.com/irees))
- Datastore needs to read and store full operatorsInFeed array of hashes from Feed Registry [\#144](https://github.com/transitland/transitland-datastore/pull/144) ([drewda](https://github.com/drewda))
- upgrade rgeo dependency & provide convex hull class method [\#142](https://github.com/transitland/transitland-datastore/pull/142) ([drewda](https://github.com/drewda))
- Geohash Helper, ported from mapzen-geohash [\#139](https://github.com/transitland/transitland-datastore/pull/139) ([irees](https://github.com/irees))
- ScheduleStopPair endpoint should include all query params in next page URL [\#138](https://github.com/transitland/transitland-datastore/pull/138) ([drewda](https://github.com/drewda))
- Fix incorrect method name [\#137](https://github.com/transitland/transitland-datastore/pull/137) ([irees](https://github.com/irees))
- expand Feed and Operator data models to support feed report attributes [\#136](https://github.com/transitland/transitland-datastore/pull/136) ([drewda](https://github.com/drewda))
- Add timezone attributes [\#135](https://github.com/transitland/transitland-datastore/pull/135) ([irees](https://github.com/irees))
- updating gems [\#134](https://github.com/transitland/transitland-datastore/pull/134) ([drewda](https://github.com/drewda))
- admin interface Rails engine/component: adding descriptive information [\#133](https://github.com/transitland/transitland-datastore/pull/133) ([drewda](https://github.com/drewda))
- Updated since [\#132](https://github.com/transitland/transitland-datastore/pull/132) ([irees](https://github.com/irees))
- Schedule additions [\#131](https://github.com/transitland/transitland-datastore/pull/131) ([irees](https://github.com/irees))
- Schedules implementation [\#130](https://github.com/transitland/transitland-datastore/pull/130) ([irees](https://github.com/irees))
- production deploy: piecemeal FeedEater process with better logging [\#129](https://github.com/transitland/transitland-datastore/pull/129) ([drewda](https://github.com/drewda))
- Catch and log uncaught exceptions [\#127](https://github.com/transitland/transitland-datastore/pull/127) ([irees](https://github.com/irees))
- Sort change payloads by created\_at [\#126](https://github.com/transitland/transitland-datastore/pull/126) ([irees](https://github.com/irees))
- FeedEater logging/stability [\#125](https://github.com/transitland/transitland-datastore/pull/125) ([drewda](https://github.com/drewda))
- piecemeal changeset payloads & FeedEater that no longer requires long requests [\#123](https://github.com/transitland/transitland-datastore/pull/123) ([drewda](https://github.com/drewda))
- admin interface should also truncate the new ChangePayload table [\#122](https://github.com/transitland/transitland-datastore/pull/122) ([drewda](https://github.com/drewda))
- Bump transitland-python-client version to use new incremental upload feature [\#121](https://github.com/transitland/transitland-datastore/pull/121) ([irees](https://github.com/irees))
- Changeset refactor 2 [\#120](https://github.com/transitland/transitland-datastore/pull/120) ([irees](https://github.com/irees))
- Bump transitland-python-client version to 0.5.6. [\#119](https://github.com/transitland/transitland-datastore/pull/119) ([irees](https://github.com/irees))
- API pagination links should include any existing query parameters [\#118](https://github.com/transitland/transitland-datastore/pull/118) ([drewda](https://github.com/drewda))
- remove asset pipeline -- it's overkill for getting one CSS file into /admin [\#117](https://github.com/transitland/transitland-datastore/pull/117) ([drewda](https://github.com/drewda))
- nest CSS and JS assets under /admin/assets [\#116](https://github.com/transitland/transitland-datastore/pull/116) ([drewda](https://github.com/drewda))
- Changeset append [\#115](https://github.com/transitland/transitland-datastore/pull/115) ([irees](https://github.com/irees))
- adding an admin dashboard under /admin & expose a way for admins to reset Datastore [\#113](https://github.com/transitland/transitland-datastore/pull/113) ([drewda](https://github.com/drewda))
- Separate worker for GTFS artifacts [\#112](https://github.com/transitland/transitland-datastore/pull/112) ([irees](https://github.com/irees))
- Rails 4.2.3 and gem updates [\#110](https://github.com/transitland/transitland-datastore/pull/110) ([drewda](https://github.com/drewda))
- in dev, the DB connection pool is limited 5, so Sidekiq should run 5 threads [\#109](https://github.com/transitland/transitland-datastore/pull/109) ([drewda](https://github.com/drewda))
- Feedeater child jobs [\#108](https://github.com/transitland/transitland-datastore/pull/108) ([irees](https://github.com/irees))
- releasing identifier\_starts\_with query param [\#107](https://github.com/transitland/transitland-datastore/pull/107) ([drewda](https://github.com/drewda))
- routes endpoint should also serve out GeoJSON [\#106](https://github.com/transitland/transitland-datastore/pull/106) ([drewda](https://github.com/drewda))
- Identifier-starts-with queries [\#105](https://github.com/transitland/transitland-datastore/pull/105) ([drewda](https://github.com/drewda))
- production deploy [\#104](https://github.com/transitland/transitland-datastore/pull/104) ([drewda](https://github.com/drewda))
- wheelchair\_boarding is gtfs attribute [\#103](https://github.com/transitland/transitland-datastore/pull/103) ([irees](https://github.com/irees))
- S3 upload: it's actually ENV\['AWS\_ACCESS\_KEY\_ID'\] [\#102](https://github.com/transitland/transitland-datastore/pull/102) ([drewda](https://github.com/drewda))
- at end of FeedEater jobs, enqueue another async job to upload artifacts to S3 [\#101](https://github.com/transitland/transitland-datastore/pull/101) ([drewda](https://github.com/drewda))
- ConflateStopsWithOsmWorker should only get enqueued after DB transactions are complete [\#100](https://github.com/transitland/transitland-datastore/pull/100) ([drewda](https://github.com/drewda))
- Tyr service improvements [\#99](https://github.com/transitland/transitland-datastore/pull/99) ([drewda](https://github.com/drewda))
- Update transitland-python-client to include vehicle\_type in tags [\#98](https://github.com/transitland/transitland-datastore/pull/98) ([irees](https://github.com/irees))
- update deploy script to reflect commit 0b1a3ca [\#97](https://github.com/transitland/transitland-datastore/pull/97) ([drewda](https://github.com/drewda))
- deploying improvements \(and deploy config changes\) to production [\#96](https://github.com/transitland/transitland-datastore/pull/96) ([drewda](https://github.com/drewda))
- search by tag [\#95](https://github.com/transitland/transitland-datastore/pull/95) ([drewda](https://github.com/drewda))
- Feedeater fix 2 [\#94](https://github.com/transitland/transitland-datastore/pull/94) ([irees](https://github.com/irees))
- Set up circleci to deploy to production [\#93](https://github.com/transitland/transitland-datastore/pull/93) ([rmarianski](https://github.com/rmarianski))
- route JSON: include operator Onestop ID and name [\#92](https://github.com/transitland/transitland-datastore/pull/92) ([drewda](https://github.com/drewda))
- Feed imports log exceptions [\#91](https://github.com/transitland/transitland-datastore/pull/91) ([drewda](https://github.com/drewda))
- FeedEater webhook can take `feed\_onestop\_ids` as an optional parameter [\#90](https://github.com/transitland/transitland-datastore/pull/90) ([drewda](https://github.com/drewda))
- add Sentry for Rails exception tracking [\#89](https://github.com/transitland/transitland-datastore/pull/89) ([drewda](https://github.com/drewda))
- update transitland-ruby-client to get Git over HTTP [\#88](https://github.com/transitland/transitland-datastore/pull/88) ([drewda](https://github.com/drewda))
- TYR/Valhalla URL can now be configured by ENV\['TYR\_HOST'\] [\#87](https://github.com/transitland/transitland-datastore/pull/87) ([drewda](https://github.com/drewda))
- Feedeater improved changeset [\#86](https://github.com/transitland/transitland-datastore/pull/86) ([irees](https://github.com/irees))
- add Feed and FeedImport models & FeedEater now uses that Ruby code [\#84](https://github.com/transitland/transitland-datastore/pull/84) ([drewda](https://github.com/drewda))
- Feedeater fix validator [\#83](https://github.com/transitland/transitland-datastore/pull/83) ([irees](https://github.com/irees))
- standardize on `TYR\_AUTH\_TOKEN` as a env variable for both Rails and Python code [\#82](https://github.com/transitland/transitland-datastore/pull/82) ([drewda](https://github.com/drewda))
- reference transitland-ruby-client by version tag [\#81](https://github.com/transitland/transitland-datastore/pull/81) ([drewda](https://github.com/drewda))
- update schema.rb and annotations [\#80](https://github.com/transitland/transitland-datastore/pull/80) ([drewda](https://github.com/drewda))
- standardize on TRANSITLAND\_DATASTORE\_HOST env variable [\#79](https://github.com/transitland/transitland-datastore/pull/79) ([drewda](https://github.com/drewda))
- remove NewRelic and Skylight [\#78](https://github.com/transitland/transitland-datastore/pull/78) ([drewda](https://github.com/drewda))
- rake enqueue\_feed\_eater\_worker task can now take Onestop IDs for feeds [\#77](https://github.com/transitland/transitland-datastore/pull/77) ([drewda](https://github.com/drewda))
- JSON pagination fix [\#76](https://github.com/transitland/transitland-datastore/pull/76) ([drewda](https://github.com/drewda))
- Bug fix; did not update \_\_main\_\_ to use task [\#75](https://github.com/transitland/transitland-datastore/pull/75) ([irees](https://github.com/irees))
- Specify commits/tags for dependencies [\#73](https://github.com/transitland/transitland-datastore/pull/73) ([irees](https://github.com/irees))
- FeedEaterWorker: mock all Python calls [\#72](https://github.com/transitland/transitland-datastore/pull/72) ([drewda](https://github.com/drewda))
- Feedeater improvements [\#71](https://github.com/transitland/transitland-datastore/pull/71) ([irees](https://github.com/irees))
- when serializing Stop JSON, include RouteServingStop relationships [\#70](https://github.com/transitland/transitland-datastore/pull/70) ([drewda](https://github.com/drewda))
- TRANSITLAND\_DATASTORE\_AUTH\_TOKEN is now the standard [\#69](https://github.com/transitland/transitland-datastore/pull/69) ([drewda](https://github.com/drewda))
- for now FeedEaterWorker spec will skip system calls to Python code [\#68](https://github.com/transitland/transitland-datastore/pull/68) ([drewda](https://github.com/drewda))
- Use TRANSITLAND\_FEED\_DATA\_PATH for feedeater data [\#67](https://github.com/transitland/transitland-datastore/pull/67) ([irees](https://github.com/irees))
- Update transitland-ruby-client [\#66](https://github.com/transitland/transitland-datastore/pull/66) ([drewda](https://github.com/drewda))
- Python virtualenv [\#65](https://github.com/transitland/transitland-datastore/pull/65) ([irees](https://github.com/irees))
- API endpoints now allow filtering by `?onestop\_id=` [\#64](https://github.com/transitland/transitland-datastore/pull/64) ([drewda](https://github.com/drewda))
- FeedEater Implementation [\#63](https://github.com/transitland/transitland-datastore/pull/63) ([irees](https://github.com/irees))
- async job to conflate Stop's against OSM way IDs [\#62](https://github.com/transitland/transitland-datastore/pull/62) ([drewda](https://github.com/drewda))
- URI style identifiers [\#61](https://github.com/transitland/transitland-datastore/pull/61) ([drewda](https://github.com/drewda))
- Gem updates [\#60](https://github.com/transitland/transitland-datastore/pull/60) ([drewda](https://github.com/drewda))
- starting to move Spindle Server into Datastore [\#59](https://github.com/transitland/transitland-datastore/pull/59) ([drewda](https://github.com/drewda))
- Serializer performance [\#58](https://github.com/transitland/transitland-datastore/pull/58) ([drewda](https://github.com/drewda))
- File download options [\#57](https://github.com/transitland/transitland-datastore/pull/57) ([drewda](https://github.com/drewda))
- secure with an API token \(hard coded\) [\#56](https://github.com/transitland/transitland-datastore/pull/56) ([drewda](https://github.com/drewda))
- V1 polish [\#55](https://github.com/transitland/transitland-datastore/pull/55) ([drewda](https://github.com/drewda))
- removing New Relic and try rack-mini-profiler [\#53](https://github.com/transitland/transitland-datastore/pull/53) ([drewda](https://github.com/drewda))
- API: changing the name of keys on OperatorServingStop records [\#52](https://github.com/transitland/transitland-datastore/pull/52) ([drewda](https://github.com/drewda))
- Reduce size of API queries [\#51](https://github.com/transitland/transitland-datastore/pull/51) ([drewda](https://github.com/drewda))
- temporarily adding New Relic [\#50](https://github.com/transitland/transitland-datastore/pull/50) ([drewda](https://github.com/drewda))
- Serializer caching [\#49](https://github.com/transitland/transitland-datastore/pull/49) ([drewda](https://github.com/drewda))
- API: when listing OperatorsServingStop, include the operator name [\#48](https://github.com/transitland/transitland-datastore/pull/48) ([drewda](https://github.com/drewda))
- CORS headers to allow all access [\#47](https://github.com/transitland/transitland-datastore/pull/47) ([drewda](https://github.com/drewda))
- delete public files [\#46](https://github.com/transitland/transitland-datastore/pull/46) ([meghanhade](https://github.com/meghanhade))
- change popup text color [\#45](https://github.com/transitland/transitland-datastore/pull/45) ([meghanhade](https://github.com/meghanhade))
- disable zoom, disable fitbounds [\#44](https://github.com/transitland/transitland-datastore/pull/44) ([meghanhade](https://github.com/meghanhade))
- Playground [\#43](https://github.com/transitland/transitland-datastore/pull/43) ([meghanhade](https://github.com/meghanhade))
- API endpoints for `operatedBy` and `servedBy` queries [\#41](https://github.com/transitland/transitland-datastore/pull/41) ([drewda](https://github.com/drewda))
- API endpoints that allow searching by identifier should also search name fields in the same query [\#40](https://github.com/transitland/transitland-datastore/pull/40) ([drewda](https://github.com/drewda))
- API endpoints: allow the number per page to be specified [\#39](https://github.com/transitland/transitland-datastore/pull/39) ([drewda](https://github.com/drewda))
- allow for searching for routes by bbox [\#38](https://github.com/transitland/transitland-datastore/pull/38) ([drewda](https://github.com/drewda))
- Fixes for route changesets [\#37](https://github.com/transitland/transitland-datastore/pull/37) ([drewda](https://github.com/drewda))
- allow for `~` and `@` in the name component of a Onestop ID [\#36](https://github.com/transitland/transitland-datastore/pull/36) ([drewda](https://github.com/drewda))
- Route geometry [\#35](https://github.com/transitland/transitland-datastore/pull/35) ([drewda](https://github.com/drewda))
- Update gems and fix specs [\#34](https://github.com/transitland/transitland-datastore/pull/34) ([drewda](https://github.com/drewda))
- updating airborne gem and its dependencies [\#33](https://github.com/transitland/transitland-datastore/pull/33) ([drewda](https://github.com/drewda))
- Upgrade Rails and gems [\#32](https://github.com/transitland/transitland-datastore/pull/32) ([drewda](https://github.com/drewda))
- Operator route stop relationship R2 [\#31](https://github.com/transitland/transitland-datastore/pull/31) ([drewda](https://github.com/drewda))
- Operator route stop relationship r1 [\#30](https://github.com/transitland/transitland-datastore/pull/30) ([drewda](https://github.com/drewda))
- renaming the app to Transitland Datastore [\#28](https://github.com/transitland/transitland-datastore/pull/28) ([drewda](https://github.com/drewda))
- add Operator and OperatorServingStop [\#27](https://github.com/transitland/transitland-datastore/pull/27) ([drewda](https://github.com/drewda))
- constrain map zoom [\#26](https://github.com/transitland/transitland-datastore/pull/26) ([drewda](https://github.com/drewda))
- rake import\_from\_gtfs task should also be able to fetch from remote URL [\#25](https://github.com/transitland/transitland-datastore/pull/25) ([drewda](https://github.com/drewda))
- Add slippy map [\#24](https://github.com/transitland/transitland-datastore/pull/24) ([meghanhade](https://github.com/meghanhade))
- Update gems [\#22](https://github.com/transitland/transitland-datastore/pull/22) ([drewda](https://github.com/drewda))
- Changesets [\#20](https://github.com/transitland/transitland-datastore/pull/20) ([drewda](https://github.com/drewda))
- automatically generate and assign Onestop IDs [\#19](https://github.com/transitland/transitland-datastore/pull/19) ([drewda](https://github.com/drewda))
- waffle.io Badge [\#8](https://github.com/transitland/transitland-datastore/pull/8) ([waffle-iron](https://github.com/waffle-iron))
- deploy from circle [\#3](https://github.com/transitland/transitland-datastore/pull/3) ([heffergm](https://github.com/heffergm))
- improving pagination for JSON output [\#2](https://github.com/transitland/transitland-datastore/pull/2) ([drewda](https://github.com/drewda))
- API 1.0.0: Stop's and StopIdentifier's [\#1](https://github.com/transitland/transitland-datastore/pull/1) ([drewda](https://github.com/drewda))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*