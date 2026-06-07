{ config, ... }:

{
  home.file.".gradle/gradle.properties".text = ''
    systemProp.http.proxyHost=127.0.0.1
    systemProp.http.proxyPort=${config.proxy.httpPublic}
    systemProp.https.proxyHost=127.0.0.1
    systemProp.https.proxyPort=${config.proxy.httpPublic}
  '';
}
