environments {
	DEV1 {
		server {
		    host='10.213.8.123'
		    user='mhedev'
			password='DEV1p@ss'
		}		
		informaticaServer {
		    host='10.213.243.31'
		    user='unagaich'
			password='winter1'
		}
		database {
			host='10.213.242.202'
			port='1534'
			service='SPDHDEVC'
		    user='apps'
			password='appsdev2'
		}
		ORACLE_HOME_PATH='/env346/Norashr/DEV1/dev1ora/8.0.6'
		LOCAL_FMB_DIRECTORY='src/main/resources/releaseName/forms'
		REMOTE_FORM_DIRECTORY='/env346/Norashr/DEV1/dev1appl/mheau/11.5.0/forms/US'
		TNS_ADMIN='/env346/Norashr/DEV1/dev1ora/8.0.6/network/admin/DEV1_nj09mhe5019'
		FMX_COMMAND='/env346/Norashr/DEV1/dev1ora/8.0.6/bin/f60gen Module=FMB_FILE_NAME Userid=apps/dev1apps Output_file=FMX_FILE_NAME'
		ENVIRONMENT_PATH='/env346/Norashr/DEV1/dev1appl/APPSDEV1_nj09mhe5019.env'
		CONFIG_PATH='/env346/Norashr/DEV1/dev1ora/8.0.6/bin'
	}
	DEV2 {
		server {
		    host='10.213.8.123'
		    user='mhedev'
			password='p@ssDEV1'
		}
		database {
			host='10.213.242.202'
			port='1534'
			service='SPDHDEVC'
		    user='apps'
			password='appsdev2'
		}
		ORACLE_HOME_PATH='/env346/Norashr/DEV1/dev1ora/8.0.6'
		LOCAL_FMB_DIRECTORY='src/main/resources/releaseName/forms'
		REMOTE_FORM_DIRECTORY='/env346/Norashr/DEV1/dev1appl/mheau/11.5.0/forms/US'
	}
}