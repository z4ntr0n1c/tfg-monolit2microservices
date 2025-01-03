# LAMP Stack Deployment in Kubernetes with Helm

Aquesta guia descriu com desplegar una pila LAMP (Linux, Apache, MySQL, PHP) dins de Kubernetes utilitzant Helm. El Helm Chart proporciona una solució fàcil i configurable per configurar, desplegar i gestionar tots els components d'una aplicació LAMP a Kubernetes.

## Components del Chart Helm

### 1. **Apache**
- Serveix com a servidor web per a l'aplicació.
- Utilitza la imatge `httpd:2.4` per al contenidor.
- Exposa el servei a través del port 80.

### 2. **MySQL**
- Proporciona la base de dades per a l'aplicació.
- Utilitza secrets per emmagatzemar les contrasenyes de manera segura.
- Configurat per executar-se en el port 3306.
- Utilitza un volum persistent per emmagatzemar les dades de la base de dades.

### 3. **PHP**
- Gestiona el processament PHP.
- Configurat per funcionar amb Apache.
- Utilitza configuracions personalitzades per a la gestió de memòria i el temps d'execució de PHP.

---

## Fitxers i configuracions

### **Chart.yaml**:

El fitxer `Chart.yaml` és el fitxer de metadades del chart. Conté informació bàsica sobre el chart com el seu nom, versió, descripció, i dependències. Aquest fitxer és necessari per a qualsevol chart Helm i s'utilitza per identificar el chart i la seva configuració general. 

### **values.yaml**

El fitxer `values.yaml` és el lloc on es defineixen els valors per defecte que es poden utilitzar a tot el chart. És una manera senzilla de proporcionar configuracions personalitzades per als recursos que s'instal·len al Kubernetes. Els valors definits en aquest fitxer poden ser substituïts mitjançant arguments de la línia de comandes o mitjançant fitxers d'override quan s'instal·la o actualitza un chart. 

Alguns dels camps definits:

- Namespace
- Configuracions per Apache, MySQL, PHP.
- Opcions d'autoscaling.
- Configuració d'Ingress i més.

### **deployment.yaml**
Aquest fitxer conté els `Deployments` per als components Apache, MySQL i PHP.

- **Apache**: Serveix les peticions web en el port 80.
- **MySQL**: Proporciona la base de dades amb configuració de secrets i volum persistent.
- **PHP**: Processa els scripts PHP i es comunica amb Apache.

### **configmap.yaml**
Aquest fitxer s'utilitza per proporcionar configuracions personalitzades per a PHP mitjançant un fitxer `php.ini`, com per exemple:
- Límit de memòria (`memory_limit`).
- Temps màxim d'execució (`max_execution_time`).
- Mida màxima per pujar fitxers (`upload_max_filesize`).

### **hpa.yaml**
El fitxer `hpa.yaml` crea un `HorizontalPodAutoscaler` (HPA) per gestionar l'escalabilitat automàtica dels components basats en l'ús de recursos (CPU, Memòria).

- Configura mínim i màxim nombre de rèpliques.
- Ajusta la càrrega de CPU i memòria per a l'autoscaling.

### **service.yaml**
Defineix serveis per exposar els components dins de Kubernetes:

- **Apache**: Exposa el servei a través del port 80.
- **MySQL**: Exposa el servei a través del port 3306.
- **PHP**: Exposa el servei a través del port 9000 per a la comunicació amb Apache.

### **secrets.yaml**
Emmagatzema informació sensible com les contrasenyes de MySQL de manera segura. Les contrasenyes i usuaris es codifiquen en base64 per evitar l'emmagatzematge en text pla.

### **ingress.yaml**
Configura un `Ingress` que permet l'accés extern al servei Apache a través del port 8080 (per defecte).

### **storage.yaml**

Les peticions d'espai d'emmagatzematge dinàmic es defineixen aquí on es vinculen amb `PersistentVolumes (PV)` al clúster i s'assignen als Pods amb `PersistentVolumeClaims (PVC)`. 

---

## Desplegar l'aplicació

Per instal·lar aquest Helm Chart:

1. Descarrega o clona el repositori del Chart.
2. Utilitza Helm per instal·lar el chart:

    ```bash
    helm install lamp ./lamp --createnamespace lamp
    ```

3. Comprova que els serveis estan en funcionament:

    ```bash
    kubectl get pods -n lamp kubectl get pods -n lamp
    ```

---

## Configuració del Chart

### Configuració personalitzada a través de `values.yaml`:

Per configurar els valors predeterminats, edita el fitxer `values.yaml`:

- **Apache**:
  - `image`: Imatge Docker per Apache.
  - `port`: Port en el qual Apache escoltarà (per defecte 80).
  
- **MySQL**:
  - `rootPassword`: Contrasenya per l'usuari root de MySQL.
  - `user`: Usuari per a la base de dades.
  - `password`: Contrasenya per a l'usuari de la base de dades.

- **PHP**:
  - `memoryLimit`: Límit de memòria per a PHP.
  - `maxExecutionTime`: Temps màxim d'execució per a PHP.
  - `uploadMaxFilesize`: Mida màxima per als fitxers pujats.

- **Autoscaling**:
  - `enabled`: Activa o desactiva l'autoscaling.
  - `minReplicas`: Nombre mínim de rèpliques.
  - `maxReplicas`: Nombre màxim de rèpliques.

### Desplegament en un entorn de producció

Per desplegar l'aplicació en un entorn de producció, és recomanable utilitzar un `Ingress` per gestionar l'accés extern a la vostra aplicació i configurar les opcions de seguretat adequades.

---

## Contribucions

Si tens suggeriments per millorar aquest Chart Helm o detectes algun error, si us plau, obre un **issue** o envia un **pull request**.

