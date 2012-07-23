<?php

$config = array(
	// DB settings 
	/*'db' => array(
		'type' => 'db2', // mysql or db2
		'host' => '9.115.146.98',
		'port' => '50000',
		'username' => 'db2inst1',
		'password' => 'db2inst123',
		'name' => 'SUGARJOS',
    ),*/
	
	'db' => array(
		'type' => 'db2', // mysql or db2
		'host' => '9.115.146.146',
		'port' => '50001',
		'username' => 'db2inst1',
		'password' => '111111',
		'name' => 'SUGARJOS',
	),
	// default bean field/values used by Utils_Db::createInsert()
	'bean_fields' => array(
		'created_by' => '1',
		'date_entered' => '2012-01-01 00:00:00',
		'modified_user_id' => '1',
		'date_modified' => '2012-01-01 00:00:00',
	),
	
);
