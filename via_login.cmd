call %yoda%\unbundled\vitria_client_scripts\via.cmd login  -h http://54.84.45.75:8080/vitria-oi -u btao -p vitria
rem % should be escaped by %%
start chrome --new-window "http://54.84.45.75:8080/vitria-oi/app/?min=false&min.ax=false&debug=true&vttoken=%VTTOKEN%"
