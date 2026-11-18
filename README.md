# docker-inkline-town

Image Docker minimale qui sert la version compilée (Vite) de
[inkline-town](https://github.com/astark01/inkline-town), inclus en sous-module.

## Fonctionnement

Build multi-étapes ([Dockerfile](Dockerfile)) :

1. **build** (`node:24-alpine`) : `pnpm install --frozen-lockfile` puis `pnpm build`,
   et pré-compression des assets en gzip et brotli.
2. **runtime** ([static-web-server](https://static-web-server.net), basé sur `scratch`) :
   ne contient que le binaire du serveur et le dossier `dist/`.

Résultat : une image d'environ **12 Mo**, en lecture seule, qui consomme quelques Mo de RAM.
Les fichiers pré-compressés sont servis directement (pas de compression à la volée)
et les assets hashés de Vite ont un cache d'un an.

## Prérequis

- Docker avec BuildKit (par défaut depuis Docker 23)
- Le sous-module initialisé :

```sh
git clone --recurse-submodules <url-de-ce-repo>
# ou, dans un clone existant :
git submodule update --init
```

## Utilisation

Avec Docker Compose ([compose.yaml](compose.yaml)) :

```sh
docker compose up -d --build
```

Ou directement avec Docker :

```sh
docker build -t inkline-town .
docker run -d --name inkline-town --read-only -p 8080:80 --restart unless-stopped inkline-town
```

Le jeu est alors disponible sur <http://localhost:8080>.
Les autres pages du projet sont aussi servies (`/gallery.html`, `/map-lab.html`, …).

## Mettre à jour le jeu

```sh
git submodule update --remote inkline-town
git add inkline-town && git commit -m "Update inkline-town"
docker compose up -d --build
```

## Configuration

Le serveur se configure par variables d'environnement `SERVER_*`
(voir la [documentation de static-web-server](https://static-web-server.net/configuration/environment-variables/)).
Par exemple, pour changer le port interne : `-e SERVER_PORT=3000`.

## Limitation

Le partage de villes (`/t/<id>`, `/api/towns`) repose sur un Worker Cloudflare et un
bucket R2 dans le projet d'origine. Ce conteneur ne sert que les fichiers statiques :
cette fonctionnalité n'y est donc pas disponible. Le reste du jeu fonctionne entièrement
côté navigateur.
