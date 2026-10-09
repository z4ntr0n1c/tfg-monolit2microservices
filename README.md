# Monolit2Microservices

> Sergio Santamaria Bayés

🌐 **Idioma / Language:**
[🇬🇧 English](#english) · [🇪🇸 Español](#español) · [<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/Flag_of_Catalonia.svg/20px-Flag_of_Catalonia.svg.png" width="16" alt="Senyera"> Català](#català)

---

<details open>
<summary><h2 id="català"><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/Flag_of_Catalonia.svg/30px-Flag_of_Catalonia.svg.png" width="24" alt="Senyera"> Català</h2></summary>

> **TFG — Migració d'Arquitectura Monolítica a Microserveis**
>
> Sergio Santamaria Bayés

Migració d'una aplicació tradicional monolítica MediaWiki a una arquitectura basada en microserveis executada en Kubernetes, incorporant pràctiques DevOps/GitOps, orquestració de contenidors, escalat dinàmic i gestió de secrets amb HashiCorp Vault.

---

## Taula de Continguts

- [Visió general del projecte](#visió-general-del-projecte)
- [Estructura del repositori](#estructura-del-repositori)
- [Arquitectura](#arquitectura)
- [Pila tecnològica](#pila-tecnològica)
- [Requisits previs](#requisits-previs)
- [Inici ràpid](#inici-ràpid)
- [Accés als serveis](#accés-als-serveis)
- [Gestió de secrets (Vault)](#gestió-de-secrets-vault)
- [Detalls del Helm Chart](#detalls-del-helm-chart)
- [Comandes útils](#comandes-útils)
- [Documentació](#documentació)

---

## Visió general del projecte

Aquest projecte documenta i implementa la migració completa d'una aplicació monolítica LAMP+MediaWiki cap a una arquitectura de microserveis. Els objectius principals són:

- **Descomposició** — Dividir el monòlit en microserveis independents d'Apache, PHP-FPM i MySQL.
- **Orquestració** — Desplegar i gestionar els serveis en un clúster Kubernetes multinode.
- **Infraestructura com a Codi** — Automatitzar l'aprovisionament del clúster amb Vagrant i el desplegament de l'aplicació amb Helm charts.
- **Gestió de Secrets** — Centralitzar totes les credencials sensibles a HashiCorp Vault amb injecció automàtica als pods en temps d'execució.
- **Escalat automàtic** — Horizontal Pod Autoscaler (HPA) basat en la utilització de CPU i memòria.
- **GitOps** — ArgoCD per a un lliurament continu declaratiu basat en Git.
- **Observabilitat** — Kubernetes Dashboard i metrics-server per a la monitorització del clúster.

---

## Estructura del repositori

```
Project/
├── README.md                          ← Sou aquí
├── doc/                               ← Documents del TFG, diagrames, diagrama de Gantt
├── monolit/                           ← Aplicació monolítica original
│   ├── app/                           ← LocalSettings de MediaWiki + bolcat de la BD
│   └── lamp/                          ← Scripts de configuració de Docker/Vagrant
└── microservices/
    └── kubernetes_cluster_app/        ← ★ Pila de microserveis de Kubernetes
        ├── Vagrantfile                ← Aprovisionament del clúster (master + 2 workers)
        ├── deploy.sh                  ← Script de desplegament i referència d'accés
        ├── kubernetes-dashboard.yaml  ← Manifestos del Dashboard
        ├── nginx-ingress-v0.44.0.yaml ← Controlador Ingress d'NGINX
        ├── data/php/mediawiki/        ← Dades de MediaWiki (LocalSettings.php, imatges)
        └── helm/
            ├── get_helm.sh            ← Script d'instal·lació de Helm
            ├── mediawiki/             ← Helm chart — Pila MediaWiki
            │   ├── Chart.yaml
            │   ├── values.yaml
            │   ├── Dockerfile
            │   └── templates/
            │       ├── deployment.yaml       ← Desplegaments d'Apache, MySQL, PHP
            │       ├── serviceaccount.yaml    ← SA per a l'autenticació de Vault
            │       ├── secrets.yaml           ← (reemplaçat per Vault)
            │       ├── configmap.yaml
            │       ├── service.yaml
            │       ├── storage.yaml
            │       ├── ingress.yaml
            │       └── hpa.yaml
            └── lamp/                  ← Helm chart — Pila LAMP genèrica
```

---

## Arquitectura

```
                         ┌──────────────────────────────────────────┐
                         │           VirtualBox / Vagrant           │
                         │                                          │
  ┌───────────┐   ┌──────┴──────┐   ┌───────────┐   ┌───────────┐ │
  │  Host     │   │   master    │   │  worker1  │   │  worker2  │ │
  │  machine  │──▶│ 10.0.0.10   │──▶│ 10.0.0.11 │   │ 10.0.0.12 │ │
  │           │   │ (2 vCPU)    │   │ (1 vCPU)  │   │ (1 vCPU)  │ │
  └───────────┘   └──────┬──────┘   └───────────┘   └───────────┘ │
                         └──────────────────────────────────────────┘
                                │
                    Kubernetes 1.20 (kubeadm)
                    Flannel CNI  │  metrics-server
                                │
          ┌─────────────────────┼───────────────────────┐
          │                     │                       │
   vault namespace       mediawiki namespace      argocd namespace
   ┌──────────────┐    ┌──────────────────────┐   ┌──────────────┐
   │ Vault (dev)  │    │  Apache   PHP   MySQL│   │  ArgoCD      │
   │ + Injector   │──▶│  (secrets injected   │   │  Server      │
   │              │    │   by Vault Agent)    │   │              │
   └──────────────┘    └──────────────────────┘   └──────────────┘
```

---

## Pila tecnològica

| Capa | Tecnologia |
|---|---|
| Virtualització | Vagrant + VirtualBox |
| Temps d'execució de contenidors | Docker |
| Orquestració | Kubernetes 1.20 (kubeadm) |
| Xarxa | Flannel CNI + NGINX Ingress |
| Gestor de paquets | Helm 3 |
| Secrets | HashiCorp Vault (mode dev, KV-v2) |
| GitOps | ArgoCD |
| Monitorització | Kubernetes Dashboard + metrics-server |
| Aplicació | MediaWiki (Apache + PHP-FPM + MySQL 5.7) |
| Escalat | Horizontal Pod Autoscaler (HPA) |

---

## Requisits previs

- [VirtualBox](https://www.virtualbox.org/) ≥ 6.1
- [Vagrant](https://www.vagrantup.com/) ≥ 2.2
- Almenys **8 GB de RAM lliure** (el clúster assigna 2 GB × 3 VMs)
- Accés a Internet durant el primer aprovisionament (descarrega imatges de les màquines, Helm charts, imatges de contenidors)

---

## Inici ràpid

```bash
# 1. Clonar el repositori
git clone <repo-url> && cd Project/microservices/kubernetes_cluster_app

# 2. Iniciar el clúster (aprovisiona tot automàticament)
vagrant up

# 3. Accedir per SSH al node mestre
vagrant ssh master

# 4. Verificar que tots els pods estan en execució
kubectl get pods -A
```

La comanda `vagrant up` aprovisiona automàticament:

1. Clúster Kubernetes (kubeadm init + unió dels workers)
2. Flannel CNI + metrics-server
3. Kubernetes Dashboard
4. Helm 3
5. HashiCorp Vault en mode dev (+ autenticació de Kubernetes, secrets inicials, polítiques)
6. Lliurament del Helm chart de MediaWiki a l'espai de noms `mediawiki`

Consulteu [`deploy.sh`](microservices/kubernetes_cluster_app/deploy.sh) per veure la referència completa dels túnels i URLs d'accés.

---

## Accés als serveis

Tots els serveis s'executen dins de les VMs. Utilitzeu túnels SSH des de la vostra màquina host per accedir-hi.

| Servei | Comanda del túnel (terminal del host) | Redirecció de ports (dins del master) | URL |
|---|---|---|---|
| **Kubernetes Dashboard** | `ssh -L 8001:localhost:8001 -p 2222 vagrant@127.0.0.1` | `kubectl proxy &` | http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy |
| **ArgoCD** | `ssh -L 8081:localhost:8081 -p 2222 vagrant@127.0.0.1` | `kubectl port-forward svc/argocd-server -n argocd 8081:443` | https://localhost:8081 |
| **Vault UI** | `ssh -L 8200:localhost:8200 -p 2222 vagrant@127.0.0.1` | `kubectl port-forward -n vault svc/vault 8200:8200` | http://localhost:8200 (token: `root`) |
| **MediaWiki** | `ssh -L 8080:localhost:30080 -p 2222 vagrant@127.0.0.1` | — (NodePort) | http://localhost:8080/wiki |

---

## Gestió de secrets (Vault)

Totes les credencials sensibles s'emmagatzemen a **HashiCorp Vault** (mode dev, motor KV-v2) i s'injecten als pods en temps d'execució mitjançant el sidecar **Vault Agent Injector**. No s'emmagatzema cap secret a `values.yaml`, objectes Secret de Kubernetes ni al codi font.

### Com funciona

1. Vault s'executa a l'espai de noms `vault` amb el **backend d'autenticació de Kubernetes** habilitat.
2. Els pods utilitzen el ServiceAccount `mediawiki-sa` per autenticar-se amb Vault.
3. Les anotacions de Vault Agent a les plantilles dels pods indiquen a l'injector quins secrets ha de recuperar i com representar-los.
4. L'injector escriu els secrets com a fitxers carregables com a variables d'entorn a `/vault/secrets/` dins del pod.
5. Els contenidors carreguen aquests fitxers abans d'iniciar el seu procés principal.

### Rutes de Vault

| Ruta | Claus |
|---|---|
| `secret/mediawiki/mysql` | `root_password`, `database`, `user`, `password` |
| `secret/mediawiki/app` | `secret_key` (`$wgSecretKey` de MediaWiki), `upgrade_key` (`$wgUpgradeKey`) |

### Gestió de secrets

```bash
# Accediu per SSH al node master i executeu:

# Llistar els secrets
kubectl exec -n vault vault-0 -- vault kv get secret/mediawiki/mysql

# Actualitzar un secret
kubectl exec -n vault vault-0 -- vault kv put secret/mediawiki/mysql \
  root_password="NewP@ssw0rd" \
  database="wikidb" \
  user="wikiuser" \
  password="NewUserP@ss"

# Reiniciar els pods per aplicar els nous secrets
kubectl rollout restart deployment -n mediawiki
```

> **Nota:** Vault s'executa en **mode dev** — totes les dades s'emmagatzemen a la memòria i es perdran si el pod de Vault es reinicia. Això és apropiat per a un context de laboratori/TFG. Per a producció, utilitzeu el mode standalone amb emmagatzematge persistent.

---

## Detalls del Helm Chart

El Helm chart **mediawiki** (`helm/mediawiki/`) desplega tres microserveis:

| Component | Imatge | Port | Descripció |
|---|---|---|---|
| **Apache** | `httpd:latest` | 80 (NodePort 30080) | Servidor web / proxy invers |
| **PHP-FPM** | `mediawiki:latest` | 80 | Processador de l'aplicació PHP |
| **MySQL** | `mysql:5.7` | 3306 | Servidor de base de dades |

### Plantilles clau

| Plantilla | Funció |
|---|---|
| `deployment.yaml` | 3 Desplegaments (Apache, MySQL, PHP) amb anotacions de Vault Agent |
| `serviceaccount.yaml` | `mediawiki-sa` — identitat per a l'autenticació a Kubernetes de Vault |
| `service.yaml` | Serveis ClusterIP i NodePort |
| `configmap.yaml` | Apache httpd.conf, MySQL my.cnf, PHP-FPM www.conf |
| `storage.yaml` | PersistentVolumeClaims per a dades de MySQL i imatges de MediaWiki |
| `hpa.yaml` | HorizontalPodAutoscaler (1–5 rèpliques, objectiu 80% CPU/memòria) |
| `ingress.yaml` | Regles d'Ingress d'NGINX |

### Instal·lació / actualització

```bash
# Dins del node mestre
helm install mediawiki /vagrant/helm/mediawiki --create-namespace --namespace mediawiki

# Actualitzar després de fer canvis al chart
helm upgrade mediawiki /vagrant/helm/mediawiki -n mediawiki
```

---

## Comandes útils

```bash
# Estat del clúster
kubectl get nodes
kubectl get pods -A

# Registres de MediaWiki
kubectl logs -n mediawiki -l component=php -c php
kubectl logs -n mediawiki -l component=mysql -c mysql

# Verificar la injecció de Vault
kubectl exec -n mediawiki <pod-name> -c php -- cat /vault/secrets/db.env

# Estat d'HPA
kubectl get hpa -n mediawiki

# Salut de Vault
kubectl exec -n vault vault-0 -- vault status

# Destruir i recrear el clúster
vagrant destroy -f && vagrant up
```

---

## Documentació

El directori `doc/` conté el TFG complet i els materials de suport:

- **Memòria del TFG** (PDF) — Anàlisi completa de la migració i metodologia
- **Annexos** (PDF) — Documentació tècnica addicional
- **Diagrames d'arquitectura** — Agrupacions funcionals monolítiques vs. microserveis, pipeline CI/CD
- **Diagrama de Gantt** — Calendari del projecte i fases

</details>

<details>
<summary><h2 id="español">🇪🇸 Español</h2></summary>

> **TFG — Migración de Arquitectura Monolítica a Microservicios**
>
> Sergio Santamaria Bayés

Migración de una aplicación tradicional monolítica MediaWiki a una arquitectura basada en microservicios ejecutada en Kubernetes, incorporando prácticas DevOps/GitOps, orquestación de contenedores, escalado dinámico y gestión de secretos con HashiCorp Vault.

---

## Tabla de Contenidos

- [Visión general del proyecto](#visión-general-del-proyecto)
- [Estructura del repositorio](#estructura-del-repositorio-1)
- [Arquitectura](#arquitectura-1)
- [Pila tecnológica](#pila-tecnológica)
- [Requisitos previos](#requisitos-previos-1)
- [Inicio rápido](#inicio-rápido)
- [Acceso a los servicios](#acceso-a-los-servicios)
- [Gestión de secretos (Vault)](#gestión-de-secretos-vault-1)
- [Detalles del Helm Chart](#detalles-del-helm-chart-1)
- [Comandos útiles](#comandos-útiles-1)
- [Documentación](#documentación-1)

---

## Visión general del proyecto

Este proyecto documenta e implementa la migración completa de una aplicación monolítica LAMP+MediaWiki hacia una arquitectura de microservicios. Los objetivos principales son:

- **Descomposición** — Dividir el monolito en microservicios independientes de Apache, PHP-FPM y MySQL.
- **Orquestación** — Desplegar y gestionar los servicios en un clúster Kubernetes multinodo.
- **Infraestructura como Código** — Automatizar el aprovisionamiento del clúster con Vagrant y el despliegue de la aplicación con Helm charts.
- **Gestión de Secretos** — Centralizar todas las credenciales sensibles en HashiCorp Vault con inyección automática a los pods en tiempo de ejecución.
- **Autoescalado** — Horizontal Pod Autoscaler (HPA) basado en la utilización de CPU y memoria.
- **GitOps** — ArgoCD para una entrega continua declarativa basada en Git.
- **Observabilidad** — Kubernetes Dashboard y metrics-server para la monitorización del clúster.

---

## Estructura del repositorio

```
Project/
├── README.md                          ← Estás aquí
├── doc/                               ← Documentos del TFG, diagramas, diagrama de Gantt
├── monolit/                           ← Aplicación monolítica original
│   ├── app/                           ← LocalSettings de MediaWiki + volcado de la BD
│   └── lamp/                          ← Scripts de configuración de Docker/Vagrant
└── microservices/
    └── kubernetes_cluster_app/        ← ★ Pila de microservicios de Kubernetes
        ├── Vagrantfile                ← Aprovisionamiento del clúster (master + 2 workers)
        ├── deploy.sh                  ← Script de despliegue y referencia de acceso
        ├── kubernetes-dashboard.yaml  ← Manifiestos del Dashboard
        ├── nginx-ingress-v0.44.0.yaml ← Controlador Ingress de NGINX
        ├── data/php/mediawiki/        ← Datos de MediaWiki (LocalSettings.php, imágenes)
        └── helm/
            ├── get_helm.sh            ← Script de instalación de Helm
            ├── mediawiki/             ← Helm chart — Pila MediaWiki
            │   ├── Chart.yaml
            │   ├── values.yaml
            │   ├── Dockerfile
            │   └── templates/
            │       ├── deployment.yaml       ← Despliegues de Apache, MySQL, PHP
            │       ├── serviceaccount.yaml    ← SA para la autenticación de Vault
            │       ├── secrets.yaml           ← (reemplazado por Vault)
            │       ├── configmap.yaml
            │       ├── service.yaml
            │       ├── storage.yaml
            │       ├── ingress.yaml
            │       └── hpa.yaml
            └── lamp/                  ← Helm chart — Pila LAMP genérica
```

---

## Arquitectura

```
                         ┌──────────────────────────────────────────┐
                         │           VirtualBox / Vagrant           │
                         │                                          │
  ┌───────────┐   ┌──────┴──────┐   ┌───────────┐   ┌───────────┐ │
  │  Host     │   │   master    │   │  worker1  │   │  worker2  │ │
  │  machine  │──▶│ 10.0.0.10   │──▶│ 10.0.0.11 │   │ 10.0.0.12 │ │
  │           │   │ (2 vCPU)    │   │ (1 vCPU)  │   │ (1 vCPU)  │ │
  └───────────┘   └──────┬──────┘   └───────────┘   └───────────┘ │
                         └──────────────────────────────────────────┘
                                │
                    Kubernetes 1.20 (kubeadm)
                    Flannel CNI  │  metrics-server
                                │
          ┌─────────────────────┼───────────────────────┐
          │                     │                       │
   vault namespace       mediawiki namespace      argocd namespace
   ┌──────────────┐    ┌──────────────────────┐   ┌──────────────┐
   │ Vault (dev)  │    │  Apache   PHP   MySQL│   │  ArgoCD      │
   │ + Injector   │──▶│  (secrets injected   │   │  Server      │
   │              │    │   by Vault Agent)    │   │              │
   └──────────────┘    └──────────────────────┘   └──────────────┘
```

---

## Pila tecnológica

| Capa | Tecnología |
|---|---|
| Virtualización | Vagrant + VirtualBox |
| Tiempo de ejecución de contenedores | Docker |
| Orquestación | Kubernetes 1.20 (kubeadm) |
| Red | Flannel CNI + NGINX Ingress |
| Gestor de paquetes | Helm 3 |
| Secretos | HashiCorp Vault (modo dev, KV-v2) |
| GitOps | ArgoCD |
| Monitorización | Kubernetes Dashboard + metrics-server |
| Aplicación | MediaWiki (Apache + PHP-FPM + MySQL 5.7) |
| Escalado | Horizontal Pod Autoscaler (HPA) |

---

## Requisitos previos

- [VirtualBox](https://www.virtualbox.org/) ≥ 6.1
- [Vagrant](https://www.vagrantup.com/) ≥ 2.2
- Al menos **8 GB de RAM libre** (el clúster asigna 2 GB × 3 VMs)
- Acceso a Internet durante el primer aprovisionamiento (descarga imágenes de las máquinas, Helm charts, imágenes de contenedores)

---

## Inicio rápido

```bash
# 1. Clonar el repositorio
git clone <repo-url> && cd Project/microservices/kubernetes_cluster_app

# 2. Iniciar el clúster (aprovisiona todo automáticamente)
vagrant up

# 3. Acceder por SSH al nodo maestro
vagrant ssh master

# 4. Verificar que todos los pods están en ejecución
kubectl get pods -A
```

El comando `vagrant up` aprovisiona automáticamente:

1. Clúster Kubernetes (kubeadm init + unión de los workers)
2. Flannel CNI + metrics-server
3. Kubernetes Dashboard
4. Helm 3
5. HashiCorp Vault en modo dev (+ autenticación de Kubernetes, secretos iniciales, políticas)
6. Despliegue del Helm chart de MediaWiki en el espacio de nombres `mediawiki`

Consulte [`deploy.sh`](microservices/kubernetes_cluster_app/deploy.sh) para ver la referencia completa de los túneles y URLs de acceso.

---

## Acceso a los servicios

Todos los servicios se ejecutan dentro de las VMs. Utilice túneles SSH desde su máquina host para acceder a ellos.

| Servicio | Comando del túnel (terminal del host) | Redirección de puertos (dentro del master) | URL |
|---|---|---|---|
| **Kubernetes Dashboard** | `ssh -L 8001:localhost:8001 -p 2222 vagrant@127.0.0.1` | `kubectl proxy &` | http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy |
| **ArgoCD** | `ssh -L 8081:localhost:8081 -p 2222 vagrant@127.0.0.1` | `kubectl port-forward svc/argocd-server -n argocd 8081:443` | https://localhost:8081 |
| **Vault UI** | `ssh -L 8200:localhost:8200 -p 2222 vagrant@127.0.0.1` | `kubectl port-forward -n vault svc/vault 8200:8200` | http://localhost:8200 (token: `root`) |
| **MediaWiki** | `ssh -L 8080:localhost:30080 -p 2222 vagrant@127.0.0.1` | — (NodePort) | http://localhost:8080/wiki |

---

## Gestión de secretos (Vault)

Todas las credenciales sensibles se almacenan en **HashiCorp Vault** (modo dev, motor KV-v2) y se inyectan en los pods en tiempo de ejecución mediante el sidecar **Vault Agent Injector**. No se almacena ningún secreto en `values.yaml`, objetos Secret de Kubernetes ni en el código fuente.

### Cómo funciona

1. Vault se ejecuta en el espacio de nombres `vault` con el **backend de autenticación de Kubernetes** habilitado.
2. Los pods utilizan el ServiceAccount `mediawiki-sa` para autenticarse con Vault.
3. Las anotaciones de Vault Agent en las plantillas de los pods indican al inyector qué secretos recuperar y cómo representarlos.
4. El inyector escribe los secretos como archivos cargables como variables de entorno en `/vault/secrets/` dentro del pod.
5. Los contenedores cargan estos archivos antes de iniciar su proceso principal.

### Rutas de Vault

| Ruta | Claves |
|---|---|
| `secret/mediawiki/mysql` | `root_password`, `database`, `user`, `password` |
| `secret/mediawiki/app` | `secret_key` (`$wgSecretKey` de MediaWiki), `upgrade_key` (`$wgUpgradeKey`) |

### Gestión de secretos

```bash
# Acceda por SSH al nodo master y ejecute:

# Listar los secretos
kubectl exec -n vault vault-0 -- vault kv get secret/mediawiki/mysql

# Actualizar un secreto
kubectl exec -n vault vault-0 -- vault kv put secret/mediawiki/mysql \
  root_password="NewP@ssw0rd" \
  database="wikidb" \
  user="wikiuser" \
  password="NewUserP@ss"

# Reiniciar los pods para aplicar los nuevos secretos
kubectl rollout restart deployment -n mediawiki
```

> **Nota:** Vault se está ejecutando en **modo dev** — todos los datos se almacenan en la memoria y se perderán si el pod de Vault se reinicia. Esto es apropiado para un contexto de laboratorio/TFG. Para producción, utilice el modo standalone con almacenamiento persistente.

---

## Detalles del Helm Chart

El Helm chart **mediawiki** (`helm/mediawiki/`) despliega tres microservicios:

| Componente | Imagen | Puerto | Descripción |
|---|---|---|---|
| **Apache** | `httpd:latest` | 80 (NodePort 30080) | Servidor web / proxy inverso |
| **PHP-FPM** | `mediawiki:latest` | 80 | Procesador de la aplicación PHP |
| **MySQL** | `mysql:5.7` | 3306 | Servidor de base de datos |

### Plantillas clave

| Plantilla | Función |
|---|---|
| `deployment.yaml` | 3 Despliegues (Apache, MySQL, PHP) con anotaciones de Vault Agent |
| `serviceaccount.yaml` | `mediawiki-sa` — identidad para la autenticación en Kubernetes de Vault |
| `service.yaml` | Servicios ClusterIP y NodePort |
| `configmap.yaml` | Apache httpd.conf, MySQL my.cnf, PHP-FPM www.conf |
| `storage.yaml` | PersistentVolumeClaims para datos de MySQL e imágenes de MediaWiki |
| `hpa.yaml` | HorizontalPodAutoscaler (1–5 réplicas, objetivo 80% CPU/memoria) |
| `ingress.yaml` | Reglas de Ingress de NGINX |

### Instalación / actualización

```bash
# Dentro del nodo maestro
helm install mediawiki /vagrant/helm/mediawiki --create-namespace --namespace mediawiki

# Actualizar después de hacer cambios en el chart
helm upgrade mediawiki /vagrant/helm/mediawiki -n mediawiki
```

---

## Comandos útiles

```bash
# Estado del clúster
kubectl get nodes
kubectl get pods -A

# Registros de MediaWiki
kubectl logs -n mediawiki -l component=php -c php
kubectl logs -n mediawiki -l component=mysql -c mysql

# Verificar la inyección de Vault
kubectl exec -n mediawiki <pod-name> -c php -- cat /vault/secrets/db.env

# Estado de HPA
kubectl get hpa -n mediawiki

# Salud de Vault
kubectl exec -n vault vault-0 -- vault status

# Destruir y recrear el clúster
vagrant destroy -f && vagrant up
```

---

## Documentación

El directorio `doc/` contiene la memoria del TFG completa y los materiales de soporte:

- **Memoria del TFG** (PDF) — Análisis completo de la migración y metodología
- **Anexos** (PDF) — Documentación técnica adicional
- **Diagramas de arquitectura** — Agrupaciones funcionales monolíticas vs. microservicios, pipeline CI/CD
- **Diagrama de Gantt** — Calendario del proyecto y fases

</details>

<details>
<summary><h2 id="english">🇬🇧 English</h2></summary>

> **TFG — Migration of a Monolithic Architecture to Microservices**
>
> Sergio Santamaria Bayés

Migration of a traditional monolithic MediaWiki application to a microservices-based architecture running on Kubernetes, incorporating DevOps/GitOps practices, container orchestration, dynamic scaling, and secrets management with HashiCorp Vault.

---

## Table of Contents

- [Project Overview](#project-overview-2)
- [Repository Structure](#repository-structure-2)
- [Architecture](#architecture-2)
- [Technology Stack](#technology-stack-1)
- [Prerequisites](#prerequisites-2)
- [Quick Start](#quick-start-1)
- [Service Access](#service-access-1)
- [Secrets Management (Vault)](#secrets-management-vault-2)
- [Helm Chart Details](#helm-chart-details-2)
- [Useful Commands](#useful-commands-2)
- [Documentation](#documentation-2)

---

## Project Overview

This project documents and implements the end-to-end migration of a monolithic LAMP+MediaWiki application into a microservices architecture. The key objectives are:

- **Decomposition** — Split the monolith into independent Apache, PHP-FPM and MySQL microservices.
- **Orchestration** — Deploy and manage the services on a multi-node Kubernetes cluster.
- **Infrastructure as Code** — Automate cluster provisioning with Vagrant and application deployment with Helm charts.
- **Secrets Management** — Centralise all sensitive credentials in HashiCorp Vault with automatic injection into pods at runtime.
- **Autoscaling** — Horizontal Pod Autoscaler (HPA) based on CPU and memory utilisation.
- **GitOps** — ArgoCD for declarative, Git-driven continuous delivery.
- **Observability** — Kubernetes Dashboard and metrics-server for cluster monitoring.

---

## Repository Structure

```
Project/
├── README.md                          ← You are here
├── doc/                               ← TFG thesis documents, diagrams, Gantt chart
├── monolit/                           ← Original monolithic application
│   ├── app/                           ← MediaWiki LocalSettings + DB dump
│   └── lamp/                          ← Docker/Vagrant setup scripts
└── microservices/
    └── kubernetes_cluster_app/        ← ★ Kubernetes microservices stack
        ├── Vagrantfile                ← Cluster provisioning (master + 2 workers)
        ├── deploy.sh                  ← Deployment & access reference script
        ├── kubernetes-dashboard.yaml  ← Dashboard manifests
        ├── nginx-ingress-v0.44.0.yaml ← NGINX Ingress controller
        ├── data/php/mediawiki/        ← MediaWiki data (LocalSettings.php, images)
        └── helm/
            ├── get_helm.sh            ← Helm installer script
            ├── mediawiki/             ← Helm chart — MediaWiki stack
            │   ├── Chart.yaml
            │   ├── values.yaml
            │   ├── Dockerfile
            │   └── templates/
            │       ├── deployment.yaml       ← Apache, MySQL, PHP deployments
            │       ├── serviceaccount.yaml    ← SA for Vault auth
            │       ├── secrets.yaml           ← (replaced by Vault)
            │       ├── configmap.yaml
            │       ├── service.yaml
            │       ├── storage.yaml
            │       ├── ingress.yaml
            │       └── hpa.yaml
            └── lamp/                  ← Helm chart — generic LAMP stack
```

---

## Architecture

```
                         ┌──────────────────────────────────────────┐
                         │           VirtualBox / Vagrant           │
                         │                                          │
  ┌───────────┐   ┌──────┴──────┐   ┌───────────┐   ┌───────────┐ │
  │  Host     │   │   master    │   │  worker1  │   │  worker2  │ │
  │  machine  │──▶│ 10.0.0.10   │──▶│ 10.0.0.11 │   │ 10.0.0.12 │ │
  │           │   │ (2 vCPU)    │   │ (1 vCPU)  │   │ (1 vCPU)  │ │
  └───────────┘   └──────┬──────┘   └───────────┘   └───────────┘ │
                         └──────────────────────────────────────────┘
                                │
                    Kubernetes 1.20 (kubeadm)
                    Flannel CNI  │  metrics-server
                                │
          ┌─────────────────────┼───────────────────────┐
          │                     │                       │
   vault namespace       mediawiki namespace      argocd namespace
   ┌──────────────┐    ┌──────────────────────┐   ┌──────────────┐
   │ Vault (dev)  │    │  Apache   PHP   MySQL│   │  ArgoCD      │
   │ + Injector   │──▶│  (secrets injected   │   │  Server      │
   │              │    │   by Vault Agent)    │   │              │
   └──────────────┘    └──────────────────────┘   └──────────────┘
```

---

## Technology Stack

| Layer | Technology |
|---|---|
| Virtualisation | Vagrant + VirtualBox |
| Container Runtime | Docker |
| Orchestration | Kubernetes 1.20 (kubeadm) |
| Networking | Flannel CNI + NGINX Ingress |
| Package Manager | Helm 3 |
| Secrets | HashiCorp Vault (dev mode, KV-v2) |
| GitOps | ArgoCD |
| Monitoring | Kubernetes Dashboard + metrics-server |
| Application | MediaWiki (Apache + PHP-FPM + MySQL 5.7) |
| Scaling | Horizontal Pod Autoscaler (HPA) |

---

## Prerequisites

- [VirtualBox](https://www.virtualbox.org/) ≥ 6.1
- [Vagrant](https://www.vagrantup.com/) ≥ 2.2
- At least **8 GB of free RAM** (the cluster allocates 2 GB × 3 VMs)
- Internet access during first provisioning (downloads box images, Helm charts, container images)

---

## Quick Start

```bash
# 1. Clone the repository
git clone <repo-url> && cd Project/microservices/kubernetes_cluster_app

# 2. Start the cluster (provisions everything automatically)
vagrant up

# 3. SSH into the master node
vagrant ssh master

# 4. Verify all pods are running
kubectl get pods -A
```

The `vagrant up` command automatically provisions:

1. Kubernetes cluster (kubeadm init + worker joins)
2. Flannel CNI + metrics-server
3. Kubernetes Dashboard
4. Helm 3
5. HashiCorp Vault in dev mode (+ Kubernetes auth, seeded secrets, policies)
6. MediaWiki Helm release in the `mediawiki` namespace

See [`deploy.sh`](microservices/kubernetes_cluster_app/deploy.sh) for the full reference of tunnels and access URLs.

---

## Service Access

All services run inside the VMs. Use SSH tunnels from your host machine to access them.

| Service | Tunnel Command (host terminal) | Port-forward (inside master) | URL |
|---|---|---|---|
| **Kubernetes Dashboard** | `ssh -L 8001:localhost:8001 -p 2222 vagrant@127.0.0.1` | `kubectl proxy &` | http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy |
| **ArgoCD** | `ssh -L 8081:localhost:8081 -p 2222 vagrant@127.0.0.1` | `kubectl port-forward svc/argocd-server -n argocd 8081:443` | https://localhost:8081 |
| **Vault UI** | `ssh -L 8200:localhost:8200 -p 2222 vagrant@127.0.0.1` | `kubectl port-forward -n vault svc/vault 8200:8200` | http://localhost:8200 (token: `root`) |
| **MediaWiki** | `ssh -L 8080:localhost:30080 -p 2222 vagrant@127.0.0.1` | — (NodePort) | http://localhost:8080/wiki |

---

## Secrets Management (Vault)

All sensitive credentials are stored in **HashiCorp Vault** (dev mode, KV-v2 engine) and injected into pods at runtime by the **Vault Agent Injector** sidecar. No secrets are stored in `values.yaml`, Kubernetes Secret objects, or source code.

### How it works

1. Vault runs in the `vault` namespace with the **Kubernetes auth backend** enabled.
2. Pods use the `mediawiki-sa` ServiceAccount to authenticate with Vault.
3. Vault Agent annotations on the pod templates tell the injector which secrets to fetch and how to render them.
4. The injector writes secrets as env-sourceable files to `/vault/secrets/` inside the pod.
5. Containers source these files before starting their main process.

### Vault paths

| Path | Keys |
|---|---|
| `secret/mediawiki/mysql` | `root_password`, `database`, `user`, `password` |
| `secret/mediawiki/app` | `secret_key` (MediaWiki `$wgSecretKey`), `upgrade_key` (`$wgUpgradeKey`) |

### Managing secrets

```bash
# SSH into master node, then:

# List secrets
kubectl exec -n vault vault-0 -- vault kv get secret/mediawiki/mysql

# Update a secret
kubectl exec -n vault vault-0 -- vault kv put secret/mediawiki/mysql \
  root_password="NewP@ssw0rd" \
  database="wikidb" \
  user="wikiuser" \
  password="NewUserP@ss"

# Restart pods to pick up new secrets
kubectl rollout restart deployment -n mediawiki
```

> **Note:** Vault is running in **dev mode** — all data is stored in memory and will be lost if the Vault pod restarts. This is appropriate for a lab/TFG context. For production, use standalone mode with persistent storage.

---

## Helm Chart Details

The **mediawiki** Helm chart (`helm/mediawiki/`) deploys three microservices:

| Component | Image | Port | Description |
|---|---|---|---|
| **Apache** | `httpd:latest` | 80 (NodePort 30080) | Reverse proxy / web server |
| **PHP-FPM** | `mediawiki:latest` | 80 | PHP application processor |
| **MySQL** | `mysql:5.7` | 3306 | Database server |

### Key templates

| Template | Purpose |
|---|---|
| `deployment.yaml` | 3 Deployments (Apache, MySQL, PHP) with Vault Agent annotations |
| `serviceaccount.yaml` | `mediawiki-sa` — identity for Vault Kubernetes auth |
| `service.yaml` | ClusterIP and NodePort services |
| `configmap.yaml` | Apache httpd.conf, MySQL my.cnf, PHP-FPM www.conf |
| `storage.yaml` | PersistentVolumeClaims for MySQL data and MediaWiki images |
| `hpa.yaml` | HorizontalPodAutoscaler (1–5 replicas, 80% CPU/memory target) |
| `ingress.yaml` | NGINX Ingress rules |

### Install / upgrade

```bash
# Inside the master node
helm install mediawiki /vagrant/helm/mediawiki --create-namespace --namespace mediawiki

# Upgrade after chart changes
helm upgrade mediawiki /vagrant/helm/mediawiki -n mediawiki
```

---

## Useful Commands

```bash
# Cluster status
kubectl get nodes
kubectl get pods -A

# MediaWiki logs
kubectl logs -n mediawiki -l component=php -c php
kubectl logs -n mediawiki -l component=mysql -c mysql

# Verify Vault injection
kubectl exec -n mediawiki <pod-name> -c php -- cat /vault/secrets/db.env

# HPA status
kubectl get hpa -n mediawiki

# Vault health
kubectl exec -n vault vault-0 -- vault status

# Destroy and recreate cluster
vagrant destroy -f && vagrant up
```

---

## Documentation

The `doc/` directory contains the full TFG thesis and supporting materials:

- **TFG thesis** (PDF) — Complete migration analysis and methodology
- **Annexes** (PDF) — Additional technical documentation
- **Architecture diagrams** — Monolithic vs. microservices functional groupings, CI/CD pipeline
- **Gantt chart** — Project timeline and phases

</details>
