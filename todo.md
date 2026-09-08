!! revisar tipos y sus assertions
    - los path
    - los puertos, y si deberia poner Networking.firewall.allowedPortTPC/UDP directamente en los modulos importando option.servicio.port, para que nixos se cerciore si estan repetidos
!! outputs:
    - aprender a exponer mis apps

* container /virut
    - separa archivo virtualization.nix en contianer y virtualizacion
    - meter herramientas guais de ocntenedores , trivy, skopeo , crane ........
    - tools: buildah, crane, trivy, grype, cdebug
* vpn:
    - añadir netbird
* dns:
    - https://github.com/TechnitiumSoftware/DnsServer
* Escritorio:
    - poner niri como mi desktop por defecto.
    - revisar los impermancenes de sway
    - bindear rofi emoji
    - quitar kooha y bindear los screenshots de rofi
* noctalia:
    - Que se vea el gasto de ram y cpu constantemente
    - Quitar el clima
* stylix (añadir modulos)
    - noctalia, sway/niri, nvim, tmux, grub
* kmscon: (master_DMS  problematico con wayland compositor)
    - Window managers cannot be started from KMS console -> Use the kmscon-launch-gui wrapper to launch your favourite desktop environment. 
* zsh:
    - ponerle completion a todo
* nvim
    - typist
    - analizar find word leader + f + w
    - cambiar los f5-9 y revisar el f4,f10 y f12
    - remodelar el conceal
    - revisar si el autocompletado viene del lsp
    - revisar porque no puedo copiar trozos de buffer y solo lineas completas al portapapeles del sistema
    - hacer los graficos compatibles con foot
* gestion de tiempo: explorar si openobserve es valido
    - activitywatch y exporters
* qutebrowser
    - meter ranger como file explorer
* zk:
    - añadir el borrar notas
    - añadir un filtro avanzado para los metadatos
    - echarle un ojo: https://zk-org.github.io/zk/config/config.html#global-configuration-file
    - mirar si dir puede cambiar de tipo str a tipo ruta
* gdb:
    - tunearme el gdb con plugins del demonio
* scripts
    - linkding-script al clipboard (añadir el secreto)
    - pantallazo con rofi
    - headers de codigo
    - doxygens (mirar si es necesario hacerlo custom)
* homepage:
    - parametrizar los puertos
    - actualizar las apps
* linkding
    - crearlo
    - crear un script
* postgres
    - copias de seguridad
    - sincronizar el correo con la base de datos
* tlp:
    - ajustar los drivers de la bateria de mi ordenador
* foot:
    - dejar el protocolo grafico bien configurado con foot para sustituir a kitty
* impermanence:
    - usar tmpfs
* opencode:
    - reevaluarlo drasticamente
* wastebin:
    - desplegarlo
