# StayPilot Cloud MVP — Vercel + Supabase

Questa versione usa Supabase Auth e PostgreSQL al posto del database JSON locale. L'interfaccia è statica e ospitabile su Vercel. È un MVP cloud per test privato, **non ancora un SaaS commerciale pronto per utenti paganti**.

## Funzioni incluse
- Registrazione e accesso email/password tramite Supabase Auth.
- Creazione, modifica ed eliminazione delle strutture.
- Creazione, modifica, pubblicazione e cancellazione delle guide.
- Guide pubbliche su `/g/slug`, indicazioni Google Maps e link WhatsApp.
- QR code per le guide pubblicate (generato da un servizio esterno usando soltanto l'URL pubblico).
- RLS PostgreSQL per isolare strutture e guide dei singoli host.
- Interfaccia responsive.

## Setup e pubblicazione
1. Crea un progetto Supabase nuovo.
2. In Supabase **SQL Editor**, incolla ed esegui `supabase/schema.sql`.
3. Apri `public/config.js` e sostituisci i due valori vuoti con Project URL e chiave **publishable** (o `anon` legacy) del progetto. Questi due valori sono pubblici e utilizzati dal browser; **non inserire service_role, password database o chiavi segrete**.
4. In Supabase **Authentication → URL Configuration**, imposta Site URL sul dominio Vercel finale e aggiungi il dominio Vercel agli URL di redirect consentiti.
5. Crea un repository GitHub privato. Estrai lo ZIP e carica il contenuto della cartella `staypilot-release` nella radice del repository.
6. In Vercel importa il repository, scegli Framework Preset **Other** e Root Directory `.`; avvia il deploy.
7. Apri il dominio Vercel, registrati e conferma l'email se richiesto.
8. Crea una struttura, crea una guida, pubblicala e apri `/g/slug` in una finestra anonima o da un telefono non autenticato.

La schermata iniziale di configurazione salva i valori nel browser locale, utile per una prova amministrativa. Tuttavia, per i link pubblici visitati da ospiti su altri dispositivi, è indispensabile compilare `public/config.js` prima del deployment: la configurazione salvata in localStorage non si trasferisce ai visitatori.

## Test minimo obbligatorio
1. Registrare Host A e Host B.
2. Creare struttura e guida con A; verificare che B non le veda e non possa modificarle.
3. Pubblicare una guida e aprirla senza login da un browser diverso.
4. Verificare che una guida in bozza e uno slug inesistente non siano visibili.
5. Controllare console browser e log di Vercel/Supabase.

## Limiti da completare prima di vendere
- Nessun pannello amministratore completo. Il ruolo admin non è modificabile dal browser; assegnarlo solo tramite procedura SQL controllata.
- Nessun pagamento reale, Stripe Checkout/webhook, limiti piani lato server o fatturazione elettronica italiana.
- Mancano recupero password personalizzato, rate limiting aggiuntivo, audit log, test di sicurezza indipendenti, privacy policy e termini del servizio.
- Le guide pubblicate sono pubbliche e possono contenere informazioni Wi-Fi/istruzioni inserite dall'host. Inserire solo contenuti destinati agli ospiti; non inserire codici d'accesso sensibili o dati personali non necessari.
- Il servizio esterno QR riceve l'URL pubblico della guida per generare il codice.
- Questo pacchetto non migra automaticamente i dati demo del vecchio database JSON.
