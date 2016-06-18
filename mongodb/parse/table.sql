CREATE TABLE `sb_mongo_results` (
  `sec` int(11) NOT NULL,
  `threads` int(11) NOT NULL,
  `tps` double DEFAULT NULL,
  `read_ops` double DEFAULT NULL,
  `write_ops` double DEFAULT NULL,
  `rt` double DEFAULT NULL,
  `runid` varchar(2048) NOT NULL,
  `jrunid` json DEFAULT NULL,
  `workload` varchar(255) GENERATED ALWAYS AS (json_unquote(json_extract(`jrunid`,'$.workload'))) VIRTUAL,
  `engine` varchar(255) GENERATED ALWAYS AS (json_unquote(json_extract(`jrunid`,'$.engine'))) VIRTUAL,
  `cachesize` int(11) GENERATED ALWAYS AS (json_unquote(json_extract(`jrunid`,'$.cachesize'))) VIRTUAL,
  `storage` varchar(255) GENERATED ALWAYS AS (json_unquote(json_extract(`jrunid`,'$.storage'))) VIRTUAL,
  `runsign` varchar(2048) GENERATED ALWAYS AS (json_unquote(json_extract(`jrunid`,'$.runsign'))) VIRTUAL
) ENGINE=InnoDB
