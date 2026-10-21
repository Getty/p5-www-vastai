---
name: www-vastai-core
description: Use when working on WWW::VastAI — the Moo client for the Vast.ai REST APIs: module layout, operation map, transport roles, entity wrapping, error model, mock harness and tests.
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

# www-vastai — Kern

`WWW::VastAI` ist der Perl-Client für die Vast.ai-REST-APIs: Marktplatz-Suche, Instanz-Lebenszyklus, Templates, Volumes, SSH- und API-Keys, Benutzer, Rechnungen und die Serverless-Endpunkte. Diese Skill beschreibt, **wie diese Distribution gebaut ist**. Das Wire-Protokoll der Vast.ai-APIs steht im geteilten Skill `vastai-general`, die Kommandozeile `vastai` im geteilten Skill `vastai-cli` — beides wird hier nicht wiederholt.

## Die Schichten

- **`WWW::VastAI`** — der Client. Hält `api_key` (Default `$ENV{VAST_API_KEY}`), `console_url` (Default `https://console.vast.ai`), `run_url` (Default `https://run.vast.ai`) und die daraus gebauten `base_url` (`/api/v0`) und `base_url_v1` (`/api/v1`). Je Ressourcengruppe ein Lazy-Accessor: `offers`, `instances`, `templates`, `volumes`, `ssh_keys`, `api_keys`, `user`, `env_vars`, `invoices`, `endpoints`, `workergroups`. Nutzt `Role::HTTP` und `Role::OperationMap`.
- **`WWW::VastAI::API::*`** — die Controller (`Offers`, `Instances`, `Templates`, `Volumes`, `SSHKeys`, `APIKeys`, `User`, `EnvVars`, `Invoices`, `Endpoints`, `Workergroups`). Jeder hält den `client` schwach und ruft `request_op`.
- **`WWW::VastAI::*`** — die Entitäten (`Offer`, `Instance`, `Template`, `Volume`, `Endpoint`, `Workergroup`, `User`, `Invoice`, `SSHKey`, `APIKey`). `Object.pm` ist die Basis: `data` (rw) hält den dekodierten Payload, `_client` ist schwach, `init_arg` heißt `client`.
- **`Role::OperationMap`** — die einzige Routentabelle. **`Role::HTTP`** — Request, Auth, JSON, Auswertung. **`Role::IO`** + **`LWPIO`** — der Transport.

Moo-Muster stehen im Skill `getty-perl-moo`, POD- und `$VERSION`-Konventionen in `getty-perl-release-author-getty`.

### Die Entitäten

`Object` hält den Payload in `data` (rw) und den Client in `_client`; `id` liest `data->{id}`, `raw` gibt den Payload zurück, `_replace_data` tauscht ihn. Die Zugriffsmethoden der Entitäten lesen direkt aus dem Payload (`$self->data->{label}`) — es gibt keinen zweiten State. Zwei Accessoren haben einen Fallback: `Offer::ask_contract_id` auf `id` und `SSHKey::key` auf `public_key`.

## Vokabular

- **Operation** — ein benannter Eintrag der Map (`getInstance`, `listEndpoints`, …), aufgerufen über `request_op`.
- **Basis** — `v0` (`/api/v0`), `v1` (`/api/v1`), `run` (`run.vast.ai`); die Basis einer Operation entscheidet die Ziel-URL.
- **Entität** — Hülle um einen API-Payload mit Zugriffsmethoden; **Controller** — die Zugangstür zu einer Ressourcengruppe.
- **Offer** — ein Angebot im Marktplatz. `ask_contract_id` (Fallback auf `id`) ist die Nummer, unter der eine Instanz bestellt wird (`PUT /asks/{id}/`).
- **new_contract** — die Nummer der frisch bestellten Instanz; steht in der Antwort von `create`, wenn die API kein Instanz-Objekt zurückgibt.

## Die Operation Map

`_build_operation_map` in `Role::OperationMap` trägt jede Route als eine Zeile `{ method, base, path }`. `{id}`, `{user_id}`, `{ssh_key_id}` sind Pfad-Platzhalter, `base` entscheidet die Basis-URL (`v0` → `/api/v0`, `v1` → `/api/v1`, `run` → `run.vast.ai`). Die Controller enthalten keine URLs — sie kennen nur Operationsnamen wie `getInstance` oder `listEndpoints`.

```perl
$client->request_op('getInstance',
    path  => { id => 12345 },   # Pfad-Platzhalter
    query => { limit => 20 },   # nur bei GET
    body  => { image => 'x' },  # POST/PUT/DELETE
);
```

`query` wird nur bei GET gefüllt, `body` nur bei POST, PUT und DELETE. Fehlt ein Pfad-Parameter, croakt `_expand_path` mit `Missing path parameter 'id'`; ein unbekannter Operationsname croakt mit `Unknown Vast.ai operation '…'`, eine unbekannte Basis mit `Unknown Vast.ai API base '…'`.

## Antworten entpacken

Die Controller akzeptieren mehrere Hüllen für dieselbe Ressource: Angebote `offers`|`results`; Instanzen `instances` (Hash oder Liste)|`instance`|`new_contract`; Templates `templates`|`results`; Volumes `volumes`|`results`; SSH-Keys `ssh_keys`|`results`; API-Keys `api_keys`|`results`; Benutzer `user`; Subaccounts `users`|`subaccounts`|`results`; Cloud-Integrationen `cloud_integrations`|`results`; IP-Adressen `ipaddrs`|`results`; Env-Vars `secrets`|`results`; Rechnungen `invoices`|`results`; Endpunkte `endpoints`|`results`; Workergroups `workergroups`|`results`.

Antwortet die API beim Anlegen oder Ändern eines Endpunkts nur mit `{ success: 1 }` ohne `endpoint`- bzw. `workergroup`-Objekt, baut der Controller das Objekt aus der ID und den gesendeten Params.

## Der Transport

`Role::HTTP` setzt auf jeden Request `Authorization: Bearer <api_key>` und `Content-Type: application/json`, auch auf GET. Ohne API-Key croakt der Aufruf mit `No Vast.ai API key configured`. GET-Parameter wandern als Query-String in die URL, Referenzwerte werden dabei JSON-kodiert, die Parameter erscheinen sortiert nach Namen. `Role::HTTP` lädt `URI::QueryParam` ausdrücklich, damit `query_param` auf jeder URI-Version da ist (`t/query-params.t` prüft das).

Weil `base_url` und `base_url_v1` aus `console_url` gebaut werden, zieht ein anderes `console_url` beide API-Versionen mit; `run_url` ist davon unabhängig. Der Request wird mit `Log::Any` auf debug-, die Antwort auf info-Level protokolliert (`%s %s -> %s`).

`LWPIO` ist das Default-Backend (LWP::UserAgent, Timeout 30 s). Es übergibt den Body **als Bytes** (`decoded_content(charset => 'none')`) — das Dekodieren macht `Role::HTTP`. Ein eigenes Backend muss die Bytes unverändert weitergeben.

Ausgewertet wird so: ein Body, der mit `{` oder `[` beginnt, wird als JSON dekodiert; jeder andere Inhalt kommt als Rohtext zurück. Erfolgreich ist nur ein Status zwischen 200 und 299. Ein kaputter JSON-Body ist ein Fehler (`unparseable response body: …`), auch bei Status 200.

`Role::IO` ist die Naht: ein Backend braucht nur `call($request) -> $response` mit `WWW::VastAI::HTTPRequest` und `WWW::VastAI::HTTPResponse`. Der Client bekommt es über `io => $backend` — das ist der Mock-Nahtpunkt der Tests.

## Das Fehlerbild

`Role::HTTP` wirft bei jedem Fehlschlag `WWW::VastAI::Error`. Das Objekt trägt `message`, `method`, `path`, `status`, `is_network`, `data` (dekodierter Body) und `body` (roh).

- `Vast.ai API error: <msg> (status 404, GET /instances/123/)` — die API hat geantwortet und einen Fehlerstatus geliefert.
- `Vast.ai connection error: <msg> (status 500)` — es kam keine Antwort; das Backend hat den Fehler selbst erzeugt, `is_network` ist dann wahr.

Die Meldung stammt aus `msg`, `message` oder `error` der JSON-Antwort, sonst aus dem Body, sonst aus dem Status. Ein langer Body wird auf 200 Zeichen gekürzt, der vollständige Body bleibt im Attribut `body`. `is_network` setzt `LWPIO`, wenn die Antwort den Header `Client-Warning: Internal response` trägt — LWP markiert damit selbst erzeugte Antworten (DNS, Connect, TLS, Timeout).

## Fallen

- **Eingaben werden vor dem Request geprüft** — die Controller croaken selbst (`image or template_hash_id required`, `endpoint_name required`, `ssh key required`), bevor überhaupt ein Request rausgeht.
- **Schwache Referenz** — `Object::_client` und der `client` der Controller sind `weak_ref`. Der Client muss die Entitäten überleben; sonst ist `_client` undef und der Aufruf stirbt an einem undefinierten Wert.
- **Payload ersetzen oder mergen** — `Instance::update` und `Template::update` ersetzen den lokalen Payload mit der Antwort, `Endpoint::update` und `Workergroup::update` mergen die Antwort über den alten. Antwortet die API beim Template-Update nur mit `{ success: 1 }`, ist danach der lokale Payload `{ success => 1 }` — die alten Felder sind weg. `Instance::set_label` spiegelt das Label deshalb von Hand in den lokalen Payload.
- **Löschen mit Body** — Vast.ai löscht teils über die URL (`DELETE /instances/{id}/`), teils über einen JSON-Body (`DELETE /template/`, `/volumes/`, `/secrets/`). `Role::HTTP::delete` nimmt den Body optional; die Map bestimmt beides.
- **Instanz-Logs** — `instances->logs` fragt `/instances/request_logs/{id}` und lädt, kommt `result_url` zurück, den Text mit einem eigenen `LWP::UserAgent` nach. Das geht an dem IO-Backend vorbei und ohne Bearer; der Mock deckt den Zweig nicht ab.
- **Ein Request nach dem Create** — antwortet `create` nur mit einer skalaren `new_contract`, holt der Client die Instanz mit `GET /instances/{id}/` nach. Antwortet `update`/`start`/`stop` ohne Instanz-Payload, folgt derselbe Nachruf.

## Einen Endpunkt ergänzen

1. Zeile in `Role::OperationMap::_build_operation_map` (`method`, `base`, `path`, `{id}`-Platzhalter).
2. Methode im passenden `API::*`-Controller — sie ruft `request_op` und entpackt die Antwort.
3. Entitätsklasse nur, wenn die Ressource eine stabile Form hat; sie erbt von `WWW::VastAI::Object`.
4. Lazy-Accessor auf `WWW::VastAI`, wenn eine neue Ressourcengruppe dazukommt.
5. Mock-Route und Test in `t/`; bei geändertem öffentlichem Verhalten README und Inline-POD anpassen.

## Tests

Die Unit-Tests sind vollständig gemockt. Das Harness ist `t/lib/Test/WWW/VastAI/Mock` mit `mock_vast`, das eine `Test::WWW::VastAI::MockIO` als `io`-Backend einsetzt. Routen sind als `"<METHOD> <path>"` geschlüsselt, wobei die Basis abgeschnitten ist (`/api/v0`, `/api/v1`, `run.vast.ai`).

```perl
use lib 't/lib';
use Test::WWW::VastAI::Mock;

my $vast = mock_vast(
    'POST /bundles/'  => sub { my ($method, $path, %opts) = @_; [ { id => 1 } ] },
    'PUT /asks/7001/' => { new_contract => { id => 991 } },
);
```

Der Wert einer Route ist ein Coderef (bekommt `$method`, `$path` und `%opts` mit `$opts{body}` als dekodiertem Request-JSON), ein Hash- oder Arrayref (wird als 200-Body kodiert) oder ein fertiges `WWW::VastAI::HTTPResponse`. Exakte Schlüssel treffen zuerst, danach die Routen als Regex. Eine ungetroffene Route stirbt mit `No mock route for: <METHOD> <path>`. Der Pfad muss exakt treffen, Slash inklusive: die Log-Route lautet `PUT /instances/request_logs/101` ohne Slash am Ende.

`t/basic.t` lädt alle Module und prüft die Basis-URLs, `t/query-params.t` die GET-Parameter und `URI::QueryParam` ohne transitive Ladung, `t/http-io.t` die Transportklassen, `t/errors.t` das Fehlerbild, `t/entities.t` die Entitäten, `t/offers.t`, `t/instances.t`, `t/templates.t`, `t/volumes.t`, `t/accounts.t` und `t/serverless.t` die Ressourcengruppen, `t/cpanfile.t` die deklarierte LWP-Kette (die Distribution ist HTTPS-only).

```bash
prove -l t/                 # Unit-Suite, vollständig gemockt, kein Netz
prove -lv t/instances.t     # eine Datei
dzil test                   # Dist::Zilla
dzil build                  # den Dist bauen
```

### Live-Suiten

`t/90-live-vastai.t` liest nur, `t/91-live-vastai-cost.t` mietet eine echte Instanz, `t/92-live-vastai-volume.t` legt ein echtes Volume an — die beiden letzten kosten Geld. Gating: `VAST_LIVE_TEST=1` plus `VAST_API_KEY`; die Kostensuiten brauchen zusätzlich `VAST_LIVE_ALLOW_COST=1` **und** `VAST_LIVE_IMAGE` oder `VAST_LIVE_TEMPLATE_HASH_ID`, sonst skippen sie. Stellschrauben sind `VAST_LIVE_ASK_ID`, `VAST_LIVE_DISK`, `VAST_LIVE_RUNTYPE`, `VAST_LIVE_LABEL`, `VAST_LIVE_ONSTART_CMD`, `VAST_LIVE_VOLUME_SIZE`, `VAST_LIVE_VOLUME_LABEL`.

Die Helfer liegen in `t/lib/Test/WWW/VastAI/Live.pm`: `live_client`, `require_live_env`, `require_cost_env`, `unique_label`, `pick_cheapest_offer`, `public_port_for_instance`, `wait_for_http`, `wait_for_instance`.

## Grenzen

- **Diese Repo definiert die Vast.ai-API nicht** — `vastai-general` beschreibt die Protokollseite, `vastai-cli` die Kommandozeile.
- **Diese Repo bringt keine CLI mit** — `WWW::VastAI` ist eine Bibliothek.
- **Ein `prove -l t/` berührt nie das Netz** — die Live-Suiten skippen ohne ihre Umgebungsvariablen.
- **Die Distribution ist HTTPS-only** (`console.vast.ai`, `run.vast.ai`); `LWP::Protocol::https` gehört deshalb in die `cpanfile`.
