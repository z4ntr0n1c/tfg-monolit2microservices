# LAMP Stack Deployment in Kubernetes with Helm

This guide describes how to deploy a LAMP (Linux, Apache, MySQL, PHP) stack inside Kubernetes using Helm. The Helm Chart provides an easy and configurable solution for configuring, deploying, and managing all components of a LAMP application on Kubernetes.

## Components of Chart Helm

### 1. **Apache**
- Serves as a web server for the application.
- Use the `httpd:2.4` image for the container.
- Expose the service through port 80.

### 2. **MySQL**
- Provides the database for the application.
- Use secrets to store passwords securely.
- Configured to run on port 3306.
- Uses a persistent volume to store database data.

### 3. **PHP**
- Handles PHP processing.
- Configured to work with Apache.
- Use custom settings for PHP runtime and memory management.

---

## Files and settings

### **Chart.yaml**:

The `Chart.yaml` file is the chart metadata file. It contains basic information about the chart such as its name, version, description, and dependencies. This file is required for any Helm chart and is used to identify the chart and its general settings.

### **values.yaml**

The `values.yaml` file is where you define the default values ​​that can be used throughout the chart. It's a simple way to provide custom configurations for resources that are installed on Kubernetes. The values ​​defined in this file can be overridden by command line arguments or by override files when installing or updating a chart.

Some of the defined fields:

- Namespace
- Configurations for Apache, MySQL, PHP.
- Autoscaling options.
- Ingress configuration and more.

### **deployment.yaml**
This file contains the `Deployments` for the Apache, MySQL and PHP components.

- **Apache**: Serves web requests on port 80.
- **MySQL**: Provides the database with secret configuration and persistent volume.
- **PHP**: Processes PHP scripts and communicates with Apache.

### **configmap.yaml**
This file is used to provide custom settings for PHP via a `php.ini` file, such as:
- Memory limit (`memory_limit`).
- Maximum execution time (`max_execution_time`).
- Maximum size to upload files (`upload_max_filesize`).

### **hpa.yaml**
The `hpa.yaml` file creates a `HorizontalPodAutoscaler` (HPA) to handle automatic scaling of components based on resource usage (CPU, Memory).

- Configure minimum and maximum number of replicas.
- Adjust CPU and memory load for autoscaling.

### **service.yaml**
Define services to expose components within Kubernetes:

- **Apache**: Expose the service over port 80.
- **MySQL**: Expose the service over port 3306.
- **PHP**: It exposes the service over port 9000 for communication with Apache.

### **secrets.yaml**
Store sensitive information like MySQL passwords securely. Passwords and users are base64 encoded to avoid storage in plain text.

### **ingress.yaml**
Configure an `Ingress` that allows external access to the Apache service through port 8080 (default).

### **storage.yaml**

Heap space claims are defined here where they are bound with `PersistentVolumes (PV)` in the cluster and assigned to Pods with `PersistentVolumeClaims (PVC)`.
---

## Deploy the application

To install this Helm Chart:

1. Download or clone the Chart repository.
2. Use Helm to install the chart:

    ```bash
    helm install lamp ./lamp --createnamespace lamp
    ```

3. Check that the services are up and running:

    ```bash
    kubectl get pods -n lamp kubectl get pods -n lamp
    ```

---

## Chart configuration

### Custom configuration via `values.yaml`:

To set the default values, edit the `values.yaml` file:

- **Apache**:
  - `image`: Docker image for Apache.
  - `port`: Port on which Apache will listen (default 80).

- **MySQL**:
  - `rootPassword`: Password for the MySQL root user.
  - `user`: User for the database.
  - `password`: Password for the database user.

- **PHP**:
  - `memoryLimit`: Memory limit for PHP.
  - `maxExecutionTime`: Maximum execution time for PHP.
  - `uploadMaxFilesize`: Maximum size for uploaded files.

- **Autoscaling**:
  - `enabled`: Activate or deactivate autoscaling.
  - `minReplicas`: Minimum number of replicas.
  - `maxReplicas`: Maximum number of replicas.

### Deployment in a production environment

To deploy your application in a production environment, it is recommended to use an `Ingress` to manage external access to your application and configure appropriate security options.

---

## Contributions

If you have suggestions for improving this Chart Helm or spot any bugs, please open an **issue** or submit a **pull request**.
