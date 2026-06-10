{ config, ... }:

{
  home.file.".gradle/gradle.properties".text = ''
    systemProp.http.proxyHost=127.0.0.1
    systemProp.http.proxyPort=${toString config.proxy.httpPublicPort}
    systemProp.https.proxyHost=127.0.0.1
    systemProp.https.proxyPort=${toString config.proxy.httpPublicPort}
  '';
}
