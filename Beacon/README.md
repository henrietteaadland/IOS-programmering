Refleksjonnotat
--------
I Beacon-prosjektet har jeg brukt SwiftUI sammen med Geoapify API, SwiftData og CoreLocation for å bygge en app som lar brukeren utforske restauranter, kafeer og hoteller i nærheten. Data hentes asynkront fra Geoapify med async/await, dekodes med JSONDecoder og sendes videre til PlacesViewModel, som oppdaterer brukergrensesnittet automatisk gjennom @Published. På den måten flyter data direkte fra API-et til kart og listevisning uten behov for manuell oppdatering.

SwiftData brukes til å lagre vurderinger og favoritter lokalt. Når en bruker legger inn en vurdering, opprettes et nytt Rating-objekt som lagres med context.insert() og context.save(). Favoritter lagres på samme måte, og gjennomsnittsratingen beregnes ved å summere verdier for et sted og vise resultatet i grensesnittet. Dette gir en dynamisk opplevelse der endringer vises umiddelbart.

Jeg har også lagt inn tre animasjoner for å gi appen mer liv. Restauranter viser en tallerken som roterer kontinuerlig, kafeer har stigende røyk, og hoteller spretter med en spring-animasjon. Disse er laget med withAnimation og .repeatForever() for å skape bevegelse og variasjon mellom stedstyper.

Den største utfordringen var å få GPS-knappen til å oppdatere kartet riktig. Jeg løste dette ved å bruke en LocationManager med @Published og en .onChange(of:)-observatør som flytter kartet til brukerens posisjon. En annen utfordring var at kontrollpanelet dekket listen, som jeg løste ved å justere høyde og legge til padding.

Gjennom prosjektet har jeg lært hvordan asynkrone prosesser, lokal lagring og animasjoner kan kombineres for å lage en komplett SwiftUI-applikasjon som både ser bra ut og fungerer stabilt.
