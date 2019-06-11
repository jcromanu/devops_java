    #!/bin/bash
    # example wsadmin launcher
    # WAS_HOME should point to the directory for the thin client
    WAS_HOME="/MyThinClient"
    USER_INSTALL_ROOT=${WAS_HOME}
    # JAVA_HOME should point to where java is installed for the thin client
    JAVA_HOME="$WAS_HOME/ibm-java-sdk-8.0-5"
    WAS_LOGGING="-Djava.util.logging.manager=com.ibm.ws.bootstrap.WsLogManager -Djava.util.logging.configureByServer=true"
    if [[ -f ${JAVA_HOME}/bin/java ]]; then
    JAVA_EXE="${JAVA_HOME}/bin/java"
    else
    JAVA_EXE="${JAVA_HOME}/jre/bin/java"
    fi

    # For debugging the utility itself
    # WAS_DEBUG=-Djava.compiler="NONE -Xdebug -Xnoagent -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=7777"

    CLIENTSOAP="-Dcom.ibm.SOAP.ConfigURL=${USER_INSTALL_ROOT}/properties/soap.client.props"
    CLIENTSAS="-Dcom.ibm.CORBA.ConfigURL=${USER_INSTALL_ROOT}/properties/sas.client.props"
    CLIENTSSL="-Dcom.ibm.SSL.ConfigURL=${USER_INSTALL_ROOT}/properties/ssl.client.props"
    CLIENTIPC="-Dcom.ibm.IPC.ConfigURL=${USER_INSTALL_ROOT}/properties/ipc.client.props"

    # the following are wsadmin property 
    # you need to change the value to enabled to turn on trace
    wsadminTraceString=-Dcom.ibm.ws.scripting.traceString=com.ibm.*=all=enabled
    wsadminTraceFile=-Dcom.ibm.ws.scripting.traceFile=${USER_INSTALL_ROOT}/logs/wsadmin.traceout
    wsadminValOut=-Dcom.ibm.ws.scripting.validationOutput=${USER_INSTALL_ROOT}/logs/wsadmin.valout

    # this will be the server host that you will be connecting to
    wsadminHost=-Dcom.ibm.ws.scripting.host=was

    # you need to make sure the port number is the server SOAP port number you want to connect to, 
    #in this example the server SOAP port is 8879
    wsadminConnType=-Dcom.ibm.ws.scripting.connectionType=SOAP
    wsadminPort=-Dcom.ibm.ws.scripting.port=8880

    # you need to make sure the port number is the server RMI port number you want to connect to, 
    #in this example the server RMI port is 2811
    #wsadminConnType=-Dcom.ibm.ws.scripting.connectionType=RMI
    #wsadminPort=-Dcom.ibm.ws.scripting.port=2811

    # you need to make sure the port number is the server JSR160RMI port number you want to connect to,
    #in this example the server JSR160RMI port is 2811
    #wsadminConnType=-Dcom.ibm.ws.scripting.connectionType=JSR160RMI
    #wsadminPort=-Dcom.ibm.ws.scripting.port=2811

    # you need to make sure the port number is the server IPC port number you want to connect to,
    #in this example the server IPC port is 9630
    #wsadminHost=-Dcom.ibm.ws.scripting.ipchost=localhost
    #wsadminConnType=-Dcom.ibm.ws.scripting.connectionType=IPC
    #wsadminPort=-Dcom.ibm.ws.scripting.port=9630

    # specify what language you want to use with wsadmin
    #wsadminLang=-Dcom.ibm.ws.scripting.defaultLang=jacl
    wsadminLang=-Dcom.ibm.ws.scripting.defaultLang=jython

    SHELL=com.ibm.ws.scripting.WasxShell

    # If wsadmin properties is set, use it
    if [[ -n "${WSADMIN_PROPERTIES+V}" ]]; then
        WSADMIN_PROPERTIES_PROP="-Dcom.ibm.ws.scripting.wsadminprops=${WSADMIN_PROPERTIES}"
    else
        # Not set, do not use it
        WSADMIN_PROPERTIES_PROP=
    fi

    # If config consistency check is set, use it
    if [[ -n "${CONFIG_CONSISTENCY_CHECK+V}" ]]; then
        WORKSPACE_PROPERTIES="-Dconfig_consistency_check=${CONFIG_CONSISTENCY_CHECK}"
    else
        WORKSPACE_PROPERTIES=
    fi


    # Parse the input arguments
    isJavaOption=false
    nonJavaOptionCount=1

    for option in "$@"
    do     
    if [ "$option" = "-javaoption" ] ; then
        isJavaOption=true
    else
        if [ "$isJavaOption" = "true" ] ; then
            javaOption="$javaOption $option"
            isJavaOption=false
        else
            nonJavaOption[$nonJavaOptionCount]="$option"
            nonJavaOptionCount=$((nonJavaOptionCount+1))
        fi
    fi
    done

    DELIM=" "
    C_PATH="${WAS_HOME}/properties:${WAS_HOME}/com.ibm.ws.admin.client_8.5.0.jar:${WAS_HOME}/com.ibm.ws.security.crypto.jar"

    #Platform specific args...
    PLATFORM=`/bin/uname`
    case $PLATFORM in 
    AIX | Linux | SunOS | HP-UX)
        CONSOLE_ENCODING=-Dws.output.encoding=console ;;
    OS/390)
        CONSOLE_ENCODING=-Dfile.encoding=UTF-8
        EXTRA_X_ARGS="-Xnoargsconversion" ;;
    esac

    # Set java options for performance
    PLATFORM=`/bin/uname`
    case $PLATFORM in
    AIX)
        PERF_JVM_OPTIONS="-Xms256m -Xmx256m -Xquickstart" ;;
    Linux)
        PERF_JVM_OPTIONS="-Xms256m -Xmx256m -Xj9 -Xquickstart" ;;
    SunOS)
        PERF_JVM_OPTIONS="-Xms256m -Xmx256m -XX:PermSize=40m" ;;
    HP-UX)
        PERF_JVM_OPTIONS="-Xms256m -Xmx256m -XX:PermSize=40m" ;;
    OS/390)
        PERF_JVM_OPTIONS="-Xms256m -Xmx256m" ;;
    esac 

    if [[ -z "${JAASSOAP}" ]]; then
        JAASSOAP="-Djaassoap=off"
    fi

    "${JAVA_EXE}" \
        ${PERFJAVAOPTION} \
        ${EXTRA_X_ARGS} \
        -Dws.ext.dirs="$WAS_EXT_DIRS" \
        ${EXTRA_D_ARGS} \
        ${WAS_LOGGING} \
        ${javaoption} \
        ${CONSOLE_ENCODING} \
        ${WAS_DEBUG} \
        "${CLIENTSOAP}" \
        "${JAASSOAP}" \
        "${CLIENTSAS}" \
        "${CLIENTSSL}" \
        "${CLIENTIPC}" \
        ${WSADMIN_PROPERTIES_PROP} \
        ${WORKSPACE_PROPERTIES} \
        "-Duser.install.root=${USER_INSTALL_ROOT}" \
        "-Dwas.install.root=${WAS_HOME}" \
        "-Dcom.ibm.websphere.thinclient=true" \
        "-Djava.security.properties=${WAS_HOME}/properties/java.security" \
        ${wsadminTraceFile} \
        ${wsadminTraceString} \
        ${wsadminValOut} \
        ${wsadminHost} \
        ${wsadminConnType} \
        ${wsadminPort} \
        ${wsadminLang} \
        -classpath \
        "${C_PATH}" \
        com.ibm.ws.scripting.WasxShell \
        "${nonJavaOption[@]}"

    exit $?