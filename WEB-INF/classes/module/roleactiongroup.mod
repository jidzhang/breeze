{"dataOwnerSet":"","parentAlias":"roles","dataDesc":"{\"actiongroupid\":{\"title\":\"actiongroupid\",\"type\":\"Hidden\",\"fieldType\":\"varchar\",\"ourterLink\":\"actiongroup.cid\",\"fieldMemo\":\"\",\"fieldLen\":\"\",\"dataExt\":\"\",\"valueRange\":\"\",\"desc\":\"\",\"width\":\"\",\"fieldtmp\":\"\",\"islist\":\"1\",\"issearch\":\"0\",\"order\":\"\",\"orderBy\":\"0\"},\"actiongroupName\":{\"title\":\"权限名称\",\"type\":\"ReadOnly\",\"fieldType\":\"ourterField\",\"ourterLink\":\"actiongroup.displayName\",\"fieldMemo\":\"\",\"fieldLen\":\"\",\"dataExt\":\"\",\"valueRange\":\"\",\"desc\":\"\",\"width\":\"\",\"fieldtmp\":\"\",\"islist\":\"1\",\"issearch\":\"0\",\"order\":\"\",\"orderBy\":\"0\"}}","alias":"roleactiongroup","roleSetting":"[0,1,2,3,4,5,6,7]","dataRefresh":"managerRoles","data":[{"actiongroupid":"1","alias":"roleactiongroup","cid":"1","opertime":"1408083594743","nodeid":"1"},{"actiongroupid":"5","alias":"roleactiongroup","cid":"9","opertime":"1432180053027"},{"actiongroupid":"5","alias":"roleactiongroup","cid":"10","opertime":"1432180057395"},{"actiongroupid":"5","alias":"roleactiongroup","cid":"11","opertime":"1432180060469"},{"actiongroupid":"5","alias":"roleactiongroup","cid":"12","opertime":"1432180061307"},{"actiongroupid":"5","alias":"roleactiongroup","cid":"13","opertime":"1432180061498"},{"actiongroupid":"5","alias":"roleactiongroup","cid":"14","opertime":"1432180061651"},{"actiongroupid":"5","alias":"roleactiongroup","cid":"15","opertime":"1432180061895"},{"actiongroupid":"5","alias":"roleactiongroup","cid":"16","opertime":"1432180185817"},{"actiongroupid":"8","alias":"roleactiongroup","cid":"20","opertime":"1432780107531","nodeid":"1"},{"actiongroupid":"7","alias":"roleactiongroup","cid":"22","opertime":"1432797195814","nodeid":"1"},{"actiongroupid":"14","alias":"roleactiongroup","cid":"30","opertime":"1433822153847","nodeid":"1"},{"actiongroupid":"30","alias":"roleactiongroup","cid":"65","opertime":"1445853343715","nodeid":"1"},{"actiongroupid":"30","alias":"roleactiongroup","cid":"71","opertime":"1446274787594","nodeid":"1"},{"actiongroupid":"14","alias":"roleactiongroup","cid":"72","opertime":"1446274788447","nodeid":"1"},{"actiongroupid":"8","alias":"roleactiongroup","cid":"73","opertime":"1446274788597","nodeid":"1"},{"actiongroupid":"7","alias":"roleactiongroup","cid":"74","opertime":"1446274788699","nodeid":"1"},{"actiongroupid":"1","alias":"roleactiongroup","cid":"75","opertime":"1446274788786","nodeid":"1"},{"actiongroupid":"30","alias":"roleactiongroup","cid":"76","opertime":"1446274854944","nodeid":"1"},{"actiongroupid":"1","alias":"roleactiongroup","cid":"77","opertime":"1446274982200","nodeid":"1"}],"nodeName":"AUTH","isMuliTab":"","outAlias":"actiongroup","triger":{"deleteroleagroup:DELETE:AFTER":"begin \r\n      delete from  wg_rolesaction where actionCid in ( select cid  from wg_action where nodeid \u003d old.actiongroupid) and nodeid \u003d old.nodeid;\r\nend","addroleagroup:INSERT:AFTER":"begin \r\n      insert into wg_rolesaction(actionCid,nodeid,opertime,alias) select cid,new.nodeid,new.opertime,\u0027rolesAction\u0027  from wg_action where nodeid \u003d new.actiongroupid;\r\nend"},"tableName":"wg_roleactiongroup","dataMemo":"","checkField":"","displayName":"角色下权限设置"}