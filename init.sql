-- 初始化数据库脚本
-- 如果你已经有数据库脚本，可以放在这里

-- 示例：创建用户表
CREATE TABLE IF NOT EXISTS `t_users` (
  `uid` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(32) NOT NULL,
  `password` varchar(128) NOT NULL,
  `email` varchar(200) DEFAULT NULL,
  `home_url` varchar(200) DEFAULT NULL,
  `screen_name` varchar(32) DEFAULT NULL,
  `created` int(10) DEFAULT NULL,
  `activated` int(10) DEFAULT NULL,
  `logged` int(10) DEFAULT NULL,
  `group_name` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`uid`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 插入默认管理员账户（密码需要加密后再插入）
-- INSERT INTO t_users (username, password, email, screen_name, created) 
-- VALUES ('admin', '加密后的密码', 'admin@example.com', '管理员', UNIX_TIMESTAMP());

-- 其他表的创建语句...

