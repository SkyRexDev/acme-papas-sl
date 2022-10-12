# Papas ACME SA
## _Prueba técnica de acceso al puesto de Sysadmin junior._

Powered by:

[![N|Solid](https://www.pngkey.com/png/detail/243-2432863_hashicorp-terraform-logo-terraform-logo.png)](https://www.terraform.io/)
[![N|Solid](https://logodownload.org/wp-content/uploads/2021/06/google-cloud-logo.png)](https://cloud.google.com/)

## Objetivo
Papas ACME SA es una empresa ficticia que necesita desplegar su site corporativo. El objetivo de esta prueba técnica es demostrar mis capacidades para aprender a utilizar nuevas herramientas para el despliegue y aprovisionamiento automático de recursos en la nube de Google Cloud.


## Instalación

Para ejecutar esta prueba técnica es necesario tener instalado [Terraform](https://www.terraform.io) v1.3.2+.

### Ubuntu
```sh
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```
Para instalar en otras distribuciones, consultar [Download Terraform](https://www.terraform.io/downloads).

## Ejecución
Clonamos el repositorio en un directorio de trabajo.
```sh
git clone https://github.com/SkyRexDev/acme-papas-sl
```
Navegamos al directorio `acme-papas-sl`
```sh
cd acme-papas-sl/
```
Inicializamos terraform.
```sh
terraform init
```
Desplegamos nuestra arquitectura con el comando terraform apply.
```sh
terraform apply
```

## Probar la conexión al balanceador

El fichero `outputs.tf` está configurado para mostrar la IP pública del balanceador y del web-server una vez termina el despliegue de la arquitectura.

Para probar el acceso al wordpress hay que **mapear la IP del balanceador al dominio acmeonestic.com**. 
Para ello, modificaremos el fichero `/etc/hosts`.
```sh
sudo nano /etc/hosts 
```
Y añadimos el par "IP acmeonestic.com".

Desde un navegador ingresaremos la dirección http://acmeonestic.com y el proxy inverso nos devolverá la página por defecto del wordpress. 

> Nota: Es posible que nos devuelva un error 502 "bad gateway" en caso de que el web-server no responda. Esto se debe a que el web-server tarda un poco más que el proxy en configurarse y arrancar. En un minuto debería de estar solucionado. 


# Desarrollo de la solución

## Primeros pasos:
Al principio tuve que familiarizarme con los conceptos básicos de Terraform. Para ello realicé los tutoriales básicos de [Get Started](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started). El proveedor en la nube utilizado ha sido Google Cloud porque me resulta más familiar que AWS. Una vez entendidos los conceptos básicos para  y **definir**, **construir** y **destruir** infraestructura, pasé a abrirme una cuenta en GCP con la prueba gratuita de 90 días. Creé un proyecto y lo doté de credenciales de acceso para que Terraform pudiera interactuar con él. 

Mis necesidades en este punto son:
1. Investigar la nomenclatura de GCP.
2. Averiguar cómo se organizan los recursos en GCP.
3. Averiguar cómo instanciar una máquina virtual y asociarla a una red.
4. Investigar la documentación del GCP en terraform para  poder automatizar el despliegue.
   
Referencias empleadas:
1. [Descripción general de GCP](https://cloud.google.com/docs/overview).
2. [Comienza a usar Terraform](https://cloud.google.com/docs/terraform/get-started-with-terraform).
3. [Prácticas recomendadas para usar Terraform](https://cloud.google.com/docs/terraform/best-practices-for-terraform).
4. [Documentación de GCP en terraform registry](https://registry.terraform.io/providers/hashicorp/google/latest/docs).

## Mi primera VM:
Descubro que las instancias de cómputo representan máquinas virtuales alojadas en un servidor físicamente alojado en una región concreta, con unas características de CPU y memoria definidos por el tipo de máquina, y están asociadas a una red por defecto. Para crearlas, activo la API de Compute Engine manualmente. Empiezo creando dos máquinas virtuales con una imagen de `ubuntu-2204-lts` conectadas a una red por defecto con una IP pública creada aleatoriamente. 

Mis necesidades en este punto son: 
   1. Securizar el acceso SSH a las máquinas creadas.
   2. Proveerlas de los programas necesarios y de su configuración. 


> Nota: posteriormente descubro que la activación/desactivación de APIs se puede automatizar con terraform.

**En negrita recalco la(s) solución(es) empleada**.

|  | Necesidades | Posibles soluciones | Referencias
|---|---|---|---| 
| 1 | Securizar el acceso SSH a las máquinas creadas. | - Modificar el archivo .ssh/authorized_keys y añadir la clave manualmente<br>- Introducir metadatos en cada instancia de cómputo y añadir las claves<br>- **Introducir las claves ssh en los metadatos del proyecto y que éstas automáticamente se propaguen a todas las instancias creadas.** | [Crear claves SSH](https://cloud.google.com/compute/docs/connect/create-ssh-keys?hl=es_419), [Agregar claves SSH a las VM](https://cloud.google.com/compute/docs/connect/add-ssh-keys?hl=es-419)
| 2 | Proveer las máquinas del software necesario y de su configuración. |  - **Lanzar un script en la instanciación de la máquina.** <br> - Utilizar una imagen precocinada con todo el software que necesito.<br> - **Utilizar virtualización ligera (contenedores) para desplegar el software ya configurado**. | [Deploying containers](https://cloud.google.com/compute/docs/containers/deploying-containers), [Docker compose](https://docs.docker.com/compose/compose-file/), [uso de metadatos en VM](https://cloud.google.com/compute/docs/metadata/overview), [secuencias de inicialización por scripts](https://cloud.google.com/compute/docs/instances/startup-scripts/linux), [google_compute_instances](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance).



### SSH
El acceso SSH se lleva a cabo insertando una clave pública mediante el metadato `ssh-keys` del proyecto. Cada vez que se instancia una máquina nueva, se conecta al servidor de matadatos y se descarga la información. Para más información, consultar [aquí](https://cloud.google.com/compute/docs/connect/add-ssh-keys?hl=es-419#metadata).

### Web server
Para desplegar un wordpress se necesita instalar y configurar una base de datos `mysql` y el propio `wordpress`. Hacer esto a través de un script de inicialización es bastante complejo y para mantener lo más sencilla posible la solución, decidí emplear `docker` junto a `docker-compose`. 

Los detalles de configuración están en el fichero docker-compose.yml. Lo puedes consultar [aquí](https://github.com/SkyRexDev/docker-compose.git). 

El script de instalación de docker lo puedes consultar [aquí](https://github.com/SkyRexDev/acme-papas-sl/blob/main/startup_web_server.sh).

En este punto habría sido tentador cambiar la imagen de arranque de las MV a instancias de `google-cloud-os`, una imagen específicamente diseñada por Google para desplegar contenedores. Sin embargo, como indica el apartado de [limitaciones](https://cloud.google.com/compute/docs/containers/deploying-containers#limitations), solo se puede implementar un contenedor por cada instancia. Un wordpress necesita dos contenedores. Uno para levantar una BBDD `mysql` y otro para el propio `wordpress`. Para no complicar más de lo necesario la solución, me decanto por utilizar docker-compose.

### Balanceador
El "balanceador" de carga en este ejemplo particular no tiene que balancear la carga ya que solamente hay una instancia servidora. Sin embargo, sí que tiene ofrecer un servicio de **proxy inverso** que sea capaz de redirigir las peticiones HTTP al servidor web. Para ello decidí implementar un `nginx` ya que la configuración de un proxy inverso aquí es muy simple. [Script de inicialización](https://github.com/SkyRexDev/acme-papas-sl/blob/main/startup_balancer.sh).

``` sh
server {
   listen 80;
   server_name acmeonestic.com;
      location / {
         proxy_pass http://192.168.1.10:80/;
	     proxy_set_header Host '$host';
      }
}
```
> Nota: a partir de HTTP/1.1 se necesita incorporar la cabecera Host. Si no, se produce un NS_BINDING_ERROR. 

## Configuración de la red

Por defecto, Google Cloud crea una red virtual en la nube (VPC) para un proyecto nuevo con unas reglas de firewall configuradas por defecto para aceptar el tráfico desde el exterior. Esta configuración no nos interesa, ya que queremos separar la red VPC en dos subredes. Una **pública** y otra **privada** y así poder gestionar el tráfico de forma independiente. Borro manualmente la configuración por defecto y mediante terraform implemento la siguiente arquitectura de red. 

|  | Instancia | Red conectada | Dirección IP asiganda (estática) | IP pública | Reglas de firewall
|---|---|---|---|---|---|
| 1 | Balanceador | Subnet pública <br> 192.168.0.0/24 | 192.168.0.10 | Generada aleatoriamente | Permitir desde 0.0.0.0/0 <br> TCP a puertos 22, 80 y 443
| 2 | Web server. | Subnet privada <br> 192.168.1.0/24 | 192.168.1.10 | Generada aleatoriamente | Permitir desde 0.0.0.0/0 <br> TCP a puerto 22 <br> Permitir desde 192.168.0.0/24 <br> TCP a puerto 80.

La política del firewall por defecto de GCP es `deny all`, de forma que nosotros manualmente tenemos que configurar qué conexiones queremos aceptar.
Esta configuración garantiza que podemos conectarnos por SSH a ambas máquinas pero restringe el tráfico HTTP únicamente entre el balanceador y el web server.

Referencias:
- [Redes VPC](https://cloud.google.com/vpc/docs/vpc).
- [Subredes](https://cloud.google.com/vpc/docs/subnets).
- [Firewall](https://cloud.google.com/vpc/docs/firewalls).
- Documentación de terraform: [compute_firewall](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall), [compute_network](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_network), [compute_subnetwork](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_subnetwork).

# Conclusión

Gracias a terraform es posible desplegar una arquitectura en la nube con un sólo comando. El resultado de este ejercicio da como resultado la imagen de la siguiente figura.
  

[![N|Solid](https://lucid.app/publicSegments/view/b844d617-2023-4116-87a0-d733d2a7e1f6/image.png)

> Agradecimientos especiales a Alfonso Cobo, Julio Pons y José Manuel Bernabeu por orientarme y ayudarme