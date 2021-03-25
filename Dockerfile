FROM oraclelinux:7-slim
LABEL MAINTAINER="Adrian Png <adrian.png@fuzziebrain.com>"

ENV \
  # The only environment variable that should be changed!
  ORACLE_PASSWORD=adminpass \
  EM_GLOBAL_ACCESS_YN=Y \
  # DO NOT CHANGE 
  ORACLE_DOCKER_INSTALL=true \
  ORACLE_SID=XE \
  ORACLE_BASE=/opt/oracle \
  ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE \
  ORAENV_ASK=NO \
  RUN_FILE=runOracle.sh \
  SHUTDOWN_FILE=shutdownDb.sh \
  EM_REMOTE_ACCESS=enableEmRemoteAccess.sh \
  EM_RESTORE=reconfigureEm.sh \
  ORACLE_XE_RPM=oracle-database-xe-18c-1.0-1.x86_64.rpm \
  CHECK_DB_FILE=checkDBStatus.sh
    
COPY ./files/${ORACLE_XE_RPM} /tmp/

RUN yum install -y oracle-database-preinstall-18c && \
  yum install -y /tmp/${ORACLE_XE_RPM} && yum -y clean all && \
  rm -rf /tmp/${ORACLE_XE_RPM} && \
  rm -rf /var/cache/yum && \
  rm -rf /var/tmp/yum-*
    
COPY ./scripts/*.sh ${ORACLE_BASE}/scripts/

RUN chmod a+x ${ORACLE_BASE}/scripts/*.sh 

# 1521: Oracle listener
# 5500: Oracle Enterprise Manager (EM) Express listener.
EXPOSE 1521 5500

RUN mkdir -p ${ORACLE_BASE}/oradata
RUN chown oracle.oinstall ${ORACLE_BASE}/oradata
RUN /etc/init.d/oracle-xe-18c configure && \
    # APEX
    rm -rf $ORACLE_HOME/apex && \
    # ORDS
    rm -rf $ORACLE_HOME/ords && \
    # SQL Developer
    rm -rf $ORACLE_HOME/sqldeveloper && \
    # UCP connection pool
    rm -rf $ORACLE_HOME/ucp && \
    # All installer files
    rm -rf $ORACLE_HOME/lib/*.zip && \
    # OUI backup
    rm -rf $ORACLE_HOME/inventory/backup/* && \
    # Network tools help
    rm -rf $ORACLE_HOME/network/tools/help && \
    # Database upgrade assistant
    rm -rf $ORACLE_HOME/assistants/dbua && \
    # Database migration assistant
    rm -rf $ORACLE_HOME/dmu && \
    # Remove pilot workflow installer
    rm -rf $ORACLE_HOME/install/pilot && \
    # Support tools
    rm -rf $ORACLE_HOME/suptools && \
    # Temp location
    rm -rf /tmp/*

# VOLUME [ "${ORACLE_BASE}/oradata" ]

HEALTHCHECK --interval=1m --start-period=2m --retries=10 \
  CMD "$ORACLE_BASE/scripts/$CHECK_DB_FILE"

CMD exec ${ORACLE_BASE}/scripts/${RUN_FILE}