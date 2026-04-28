# 🥗 Fooyou — Project Plan

> *Je keukenvriend die bijhoudt wat je eet en wat je in huis hebt*  
> Persoonlijke voorraad- en calorie tracker voor iOS  
> Gebouwd met SwiftUI · Claude Vision API · Open Food Facts · HealthKit

-----

## 💡 De naam: Fooyou

**Fooyou** speelt op twee betekenissen van het Nederlandse woord *maat*:

- **Maat = vriend/buddy** — je vertrouwde keukenvriend
- **Maat = portie/hoeveelheid** — houdt je maatjes bij

Herkenbaar, volledig Nederlands, warm van toon. Past bij de doelgroep.

-----

## 🎯 Visie

Een iOS app die het bijhouden van je voorraden en calorieën zo eenvoudig maakt dat het voor iedereen werkt — van de developer die hem bouwt tot de partner die hem dagelijks gebruikt. Geen gedoe met handmatig invoeren. Foto van je bon, foto van je maaltijd, of recept delen vanuit de AH app — de rest doet Fooyou.

Alle voedingsdata wordt weggeschreven naar **Apple HealthKit**, zodat **Coach Leo** de voedingsgegevens kan inlezen voor de AI trainingscoach.

### Kernprincipes

- **Foto-first** — alles begint met een camera of een deelknop. Bon, maaltijd, barcode, recept.
- **Plan vooruit** — maaltijden plannen vóórdat je ze eet. Markeer als gegeten als het klaar is.
- **Raad slim, leer snel** — de app leert jouw productkeuzes en stelt ze de volgende keer voor.
- **Visueel helder** — grote knoppen, duidelijke kleuren, geen verborgen menu’s. Roos tikt één keer en weet wat er in huis is.
- **Geen verrassingen** — notificaties alleen als het echt nuttig is (bijna op, bijna verlopen).
- **Coach Leo connectie** — alle maaltijden landen in HealthKit zodat de trainingscoach rekening houdt met voeding.

-----

## 🎨 Design Filosofie

### Toon & Stijl

Warm, organisch, clean. Denk aan een modern kookboek — niet aan een fitness tracker.  
Inspiratie: de esthetiek van Nederlandse supermarkten (fris, helder, food-forward).

### Kleurpalet

```
Primair:      #2D6A4F  (diep groen — vers, gezond)
Accent:       #F4A261  (warm oranje — actie-knoppen, alerts)
Achtergrond:  #FAFAF7  (gebroken wit — warm, niet koud)
Surface:      #FFFFFF  (cards)
Tekst:        #1A1A2E  (bijna zwart)
Gepland:      #A8DADC  (lichtblauw — nog niet gegeten)
Gegeten:      #52B788  (groen — geconsumeerd en gelogd)
Waarschuwing: #E76F51  (rood-oranje — verlopen/bijna op)
```

### Maaltijd slot kleuren

```
🌅 Ontbijt:          #FFD166  (warm geel)
🍎 Snack ochtend:    #FFE8A3  (licht geel)
☀️ Lunch:            #52B788  (groen)
🍊 Snack middag:     #A8E6CF  (licht groen)
🌙 Avondeten:        #457B9D  (blauw)
🌟 Snack avond:      #A8DADC  (licht blauw)
```

### Typografie

- **Display/Titels**: SF Pro Rounded (iOS native, zacht en vriendelijk)
- **Body**: SF Pro Text
- **Cijfers/Macros**: SF Pro Mono (tabular figures voor nette uitlijning)

### UI Richtlijnen

- **Cards** met zachte slagschaduw (`shadow(radius: 8, y: 4)`)
- **Grote tap targets** — minimaal 56pt hoogte voor alle primaire acties
- **Geplande maaltijden** — gestippelde rand + lichtblauwe achtergrond tot ze gegeten zijn
- **“Markeer als gegeten”** — prominente groene knop met haptic feedback en checkmark animatie
- **Lege states** — altijd illustratief, nooit een kale lijst
- **Animaties** — spring animations bij toevoegen/verwijderen, checkmark bounce bij “gegeten”
- **Houdbaarheidsdatum** kleurcodering: 🟢 >7 dagen · 🟡 3–7 dagen · 🔴 <3 dagen · ⚫ verlopen

-----

## 🏗️ Tech Stack

|Laag           |Technologie             |Reden                                     |
|---------------|------------------------|------------------------------------------|
|UI             |SwiftUI 6               |Native iOS, animaties, previews           |
|Data lokaal    |CoreData + CloudKit     |Sync tussen apparaten (Iwan + Roos)       |
|AI vision      |Claude Haiku 4.5 API    |Bon + maaltijd + recept herkenning        |
|Producten DB   |Open Food Facts API     |Gratis, NL producten incl. AH             |
|Barcode        |AVFoundation            |Native iOS, geen dependencies             |
|Gezondheidsdata|HealthKit               |Schrijft voeding weg → Coach Leo leest dit|
|Share Extension|NSItemProvider          |Ontvangt recepten vanuit AH app           |
|Notificaties   |UserNotifications       |Lokaal, geen server nodig                 |
|Networking     |URLSession + async/await|Standaard, geen Alamofire nodig           |

### Mappenstructuur

```
Fooyou/
├── App/
│   ├── FooyouApp.swift
│   └── AppState.swift
├── Features/
│   ├── Pantry/
│   │   ├── PantryView.swift
│   │   ├── PantryViewModel.swift
│   │   └── PantryItemRow.swift
│   ├── Scanner/
│   │   ├── ReceiptScannerView.swift
│   │   ├── BarcodeScannerView.swift
│   │   └── MealScannerView.swift
│   ├── MealPlan/                        # Dag overzicht met 6 slots
│   │   ├── MealPlanView.swift
│   │   ├── MealSlotCard.swift
│   │   ├── MealPlanViewModel.swift
│   │   └── MarkAsEatenView.swift
│   ├── MealLog/
│   │   ├── DayOverviewView.swift
│   │   └── MealDetailView.swift
│   ├── Products/
│   │   ├── ProductsView.swift
│   │   └── ProductDetailView.swift
│   └── Settings/
│       └── SettingsView.swift
├── Services/
│   ├── ClaudeService.swift
│   ├── OpenFoodFactsService.swift
│   ├── BarcodeService.swift
│   ├── HealthKitService.swift
│   └── NotificationService.swift
├── Models/
│   ├── Product.swift
│   ├── PantryItem.swift
│   ├── MealSlot.swift                   # 6 vaste momenten
│   ├── PlannedMeal.swift
│   ├── MealLog.swift
│   └── ClaudeResponse.swift
├── CoreData/
│   └── Fooyou.xcdatamodeld
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
└── FooyouShareExtension/             # Aparte Xcode target
    ├── ShareViewController.swift
    ├── RecipeParserService.swift
    └── Info.plist
```

-----

## 📦 Data Modellen

### MealSlot — 6 vaste eetmomenten

```swift
enum MealSlot: String, CaseIterable, Codable {
    case breakfast      = "Ontbijt"
    case morningSnack   = "Snack ochtend"
    case lunch          = "Lunch"
    case afternoonSnack = "Snack middag"
    case dinner         = "Avondeten"
    case eveningSnack   = "Snack avond"

    var emoji: String {
        switch self {
        case .breakfast:      return "🌅"
        case .morningSnack:   return "🍎"
        case .lunch:          return "☀️"
        case .afternoonSnack: return "🍊"
        case .dinner:         return "🌙"
        case .eveningSnack:   return "🌟"
        }
    }

    // Standaard tijdstip voor HealthKit timestamp
    var defaultHour: Int {
        switch self {
        case .breakfast:      return 7
        case .morningSnack:   return 10
        case .lunch:          return 13
        case .afternoonSnack: return 16
        case .dinner:         return 18
        case .eveningSnack:   return 21
        }
    }

    // Wordt opgeslagen als HealthKit metadata → Coach Leo leest dit
    var healthKitMetadataLabel: String { rawValue }
}
```

### PlannedMeal — maaltijd plannen vóórdat je eet

```swift
struct PlannedMeal: Identifiable, Codable {
    let id: UUID
    var date: Date                      // Welke dag
    var slot: MealSlot                  // Welk moment
    var dishName: String
    var ingredients: [PlannedIngredient]
    var sourceRecipeURL: URL?           // Indien gedeeld vanuit AH
    var photo: Data?
    var servings: Int                   // Recept voor X personen
    var servingsToEat: Int              // Jij eet voor Y personen

    // Status
    var isEaten: Bool = false
    var eatenAt: Date?                  // Exact tijdstip → HealthKit timestamp

    var totalCalories: Double {
        let scale = Double(servingsToEat) / Double(servings)
        return ingredients.reduce(0) { $0 + $1.calories } * scale
    }
}

struct PlannedIngredient: Identifiable, Codable {
    let id: UUID
    var product: Product?               // Gekoppeld aan persoonlijke product DB
    var ingredientName: String          // Originele naam uit recept
    var category: String                // "chicken_breast"
    var amount: Double
    var unit: String                    // "gram", "el", "stuks"
    var calories: Double
}
```

### MealLog — definitief gelogde maaltijd

```swift
struct MealLog: Identifiable, Codable {
    let id: UUID
    let date: Date                          // Exact tijdstip gegeten
    var slot: MealSlot
    var dishName: String
    var photo: Data?
    var ingredients: [ConsumedIngredient]
    var healthKitCorrelationUUID: UUID?     // Referentie terug naar HealthKit

    var totalCalories: Double { ingredients.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double  { ingredients.reduce(0) { $0 + $1.protein  } }
    var totalFat: Double      { ingredients.reduce(0) { $0 + $1.fat      } }
    var totalCarbs: Double    { ingredients.reduce(0) { $0 + $1.carbs    } }
}

struct ConsumedIngredient: Identifiable, Codable {
    let id: UUID
    var product: Product
    var amountGrams: Double
    var calories: Double { product.caloriesPer100 / 100 * amountGrams }
    var protein: Double  { product.proteinPer100  / 100 * amountGrams }
    var fat: Double      { product.fatPer100      / 100 * amountGrams }
    var carbs: Double    { product.carbsPer100    / 100 * amountGrams }
}
```

### Product & PantryItem

```swift
struct Product: Identifiable, Codable {
    let id: UUID
    var barcode: String?
    var name: String                    // "AH Kwark 0% vet 500g"
    var brand: String
    var imageURL: URL?
    var caloriesPer100: Double
    var proteinPer100: Double
    var fatPer100: Double
    var carbsPer100: Double
    var packSizeGrams: Double
    var unit: FoodUnit                  // .gram, .ml, .stuks
    var ingredientCategories: [String]  // ["quark", "dairy", "protein"]
    var usageCount: Int                 // Leeralgoritme
    var lastUsed: Date?
    var lowStockThreshold: Double
    var defaultPortionSize: Double
}

struct PantryItem: Identifiable, Codable {
    let id: UUID
    var product: Product
    var quantity: Double
    var expiryDate: Date?
    var purchasedDate: Date
    var location: StorageLocation       // .fridge, .freezer, .pantry

    var stockStatus: StockStatus { ... }
    var expiryStatus: ExpiryStatus { ... }
}
```

-----

## 🍽️ Maaltijd Planning Flow

### De 6-slot dag view

```
┌─────────────────────────────────┐
│  Vandaag · ma 27 april       📊 │
│                                 │
│     1.247 / 2.200 kcal          │
│  ████████████░░░░░░             │
│  P: 98g   K: 142g   V: 38g     │
│                                 │
│  🌅 Ontbijt           487 kcal  │
│  ┌──────────────────────────┐   │
│  │ ✅ Kwark bowl            │   │  ← Gegeten (groene rand)
│  │    08:34 · 487 kcal      │   │
│  └──────────────────────────┘   │
│                                 │
│  🍎 Snack ochtend      210 kcal │
│  ┌──────────────────────────┐   │
│  │ ✅ Banaan + noten        │   │
│  └──────────────────────────┘   │
│                                 │
│  ☀️ Lunch             550 kcal  │
│  ┌──────────────────────────┐   │
│  │ ✅ Broodje kipfilet      │   │
│  └──────────────────────────┘   │
│                                 │
│  🍊 Snack middag        - kcal  │
│  ┌──────────────────────────┐   │
│  │    + Maaltijd plannen    │   │  ← Leeg slot
│  └──────────────────────────┘   │
│                                 │
│  🌙 Avondeten         ~425 kcal │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐   │  ← Gepland (blauwe stippellijn)
│  │ 📋 Gegrilde kip recept   │   │
│  │    Gepland · ~425 kcal   │   │
│  │  [✓ Markeer als gegeten] │   │  ← Grote groene knop
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘   │
│                                 │
│  🌟 Snack avond          - kcal │
│  ┌──────────────────────────┐   │
│  │    + Maaltijd plannen    │   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘
```

### “Markeer als gegeten” flow

```
Tap [Markeer als gegeten]
    ↓
Bottom sheet:
  - Tijdstip (default = nu, aanpasbaar)
  - Porties aanpassen (0.5× – 2× slider)
  - Ingrediënten check (kan aanpassen)
    ↓
Tap [Bevestig]
  → MealLog aanmaken in CoreData
  → Voorraad aftrekken per ingrediënt
  → HealthKit schrijven
  → Haptic feedback + groene checkmark animatie
  → Card krijgt groene rand + ✅ icoon
```

-----

## 🍏 HealthKit Integratie

### Doel

Fooyou schrijft **alleen** naar HealthKit als een maaltijd als “gegeten” is gemarkeerd.  
Coach Leo leest de voedingsdata terug om trainingsplannen af te stemmen op inname.

### Benodigde permissies (Info.plist)

```
NSHealthShareUsageDescription:
  "Fooyou leest voedingsdata om je dagelijkse inname te tonen."
NSHealthUpdateUsageDescription:
  "Fooyou schrijft je maaltijden weg zodat Coach Leo ze kan gebruiken
   voor je trainingsplanning."
```

### Te schrijven HealthKit types

```swift
let writeTypes: Set<HKSampleType> = [
    HKQuantityType(.dietaryEnergyConsumed),  // kcal
    HKQuantityType(.dietaryProtein),          // gram
    HKQuantityType(.dietaryFatTotal),         // gram
    HKQuantityType(.dietaryCarbohydrates),    // gram
    HKCorrelationType(.food)                  // bundelt alles als 1 maaltijd
]
```

### HealthKitService.swift

```swift
class HealthKitService {

    func writeMeal(_ log: MealLog) async throws -> UUID {
        let store = HKHealthStore()
        let time  = log.eatenAt ?? log.date

        let meta  = mealMetadata(for: log)

        let samples: Set<HKSample> = [
            HKQuantitySample(type: HKQuantityType(.dietaryEnergyConsumed),
                quantity: .init(unit: .kilocalorie(), doubleValue: log.totalCalories),
                start: time, end: time, metadata: meta),
            HKQuantitySample(type: HKQuantityType(.dietaryProtein),
                quantity: .init(unit: .gram(), doubleValue: log.totalProtein),
                start: time, end: time, metadata: meta),
            HKQuantitySample(type: HKQuantityType(.dietaryFatTotal),
                quantity: .init(unit: .gram(), doubleValue: log.totalFat),
                start: time, end: time, metadata: meta),
            HKQuantitySample(type: HKQuantityType(.dietaryCarbohydrates),
                quantity: .init(unit: .gram(), doubleValue: log.totalCarbs),
                start: time, end: time, metadata: meta),
        ]

        // HKCorrelation bundelt alles als één maaltijdinvoer in de Health app
        let correlation = HKCorrelation(
            type: HKCorrelationType(.food),
            start: time, end: time,
            objects: samples,
            metadata: meta
        )

        try await store.save(correlation)
        return correlation.uuid
    }

    private func mealMetadata(for log: MealLog) -> [String: Any] {
        [
            HKMetadataKeyFoodType:       log.dishName,
            "FooyouMealSlot":         log.slot.rawValue,
            // ↑ "Avondeten" — Coach Leo leest dit om trainingsplanning
            //   te combineren met voedingstiming
            "FooyouMealSlotKey":      log.slot.healthKitMetadataLabel,
            "FooyouTotalCalories":    log.totalCalories,
            "FooyouSourceApp":        "Fooyou",
        ]
    }
}
```

### Wat Coach Leo ziet

```swift
// In Coach Leo — voedingsdata opvragen voor de afgelopen week:
HKSampleQuery(sampleType: HKCorrelationType(.food), ...) { samples in
    samples.compactMap { $0 as? HKCorrelation }.forEach { meal in
        let slot     = meal.metadata?["FooyouMealSlot"] as? String  // "Avondeten"
        let calories = meal.metadata?["FooyouTotalCalories"] as? Double
        let time     = meal.startDate
        // Coach Leo kan nu:
        // - Zware trainingsdag + weinig gegeten → hersteladvies aanpassen
        // - Avondeten laat + ochtendrun vroeg → energietip geven
        // - Weekgemiddelde calorieën tonen naast trainingsbelasting
    }
}
```

-----

## 📤 Share Extension — AH Bon (PDF) + Recept Delen

De Share Extension vangt **drie content types** op, elk met een eigen flow:

|Bron                    |Type             |Gebruik                                    |
|------------------------|-----------------|-------------------------------------------|
|AH app → Bon            |**PDF**          |Digitale kassabon → voorraad importeren    |
|AH app → Recept         |**Tekst**        |Recept uitgeschreven → maaltijd plannen    |
|AH app → Recept         |**URL**          |Link naar recept → fetch → maaltijd plannen|
|Internet (Safari, Files)|**PDF**          |Gedownload recept → maaltijd plannen       |
|Andere winkel           |**Foto (camera)**|Fysieke kassabon scannen via Claude vision |


> **Bon = PDF (AH app) of foto (andere winkels)**  
> Wij hebben geen fysieke AH bon — die staat digitaal in de app als PDF.  
> Voor Lidl, Jumbo, etc. gebruik je de camera in de Scannen tab.  
> **Recepten als PDF** — van internet gedownload via Safari of opgeslagen in Files → zelfde Share Extension flow.

### PDF recepten van internet

Veel receptenwebsites en kookboekplatforms (Allerhande, Leukerecepten, Culy, etc.) bieden recepten aan als downloadbare PDF. Deze werken identiek aan de AH bon flow:

```
Safari / Files app → PDF recept → Deel → Fooyou
    ↓
ShareViewController detecteert: is dit een bon of een recept?
    ↓
Auto-detectie op basis van PDF inhoud:
  - Bevat "totaal", "€", productnamen → waarschijnlijk BON
  - Bevat "ingrediënten", "bereiden", "kcal per persoon" → waarschijnlijk RECEPT
  - Bij twijfel: gebruiker kiest zelf
    ↓
BON flow → voorraad importeren
RECEPT flow → maaltijdslot kiezen → plannen
```

### Claude prompt — PDF type detectie

```swift
let detectTypePrompt = """
Look at this Dutch document. Is it a shopping receipt or a recipe?
Return ONLY: { "type": "receipt" | "recipe" | "unknown" }
"""
// Goedkoop: stuur alleen eerste pagina als base64, max ~800 tokens
```

### Flow — AH Kassabon PDF

```
AH app → Bestellingen → Bon → Deel → Fooyou
    ↓
ShareViewController ontvangt PDF
    ↓
Twee opties (automatisch gekozen):
  A) PDFKit extraheert tekst → Claude parseert structuur
  B) PDF als base64 direct naar Claude API (native PDF support)
    ↓
Claude retourneert JSON met alle gekochte producten
    ↓
Bevestigingssheet:
  - Lijst van herkende producten
  - Per product: houdbaarheidsdatum invoeren
  - Producten die nog niet in DB zitten → automatisch aanmaken
    ↓
[Alles toevoegen aan voorraad]
```

### Flow — AH Recept (tekst of URL)

```
AH app → Recept → Deel → Fooyou
    ↓
ShareViewController ontvangt tekst of URL
    ↓
Claude parseert ingrediënten → JSON
    ↓
Sheet: datum + maaltijdslot kiezen → opslaan als gepland
```

### Xcode configuratie

```
Targets:
  ├── Fooyou               (main app)
  └── FooyouShareExtension (share extension)
      Entitlement: com.apple.security.application-groups
      App Group:   group.nl.jouwdomain.fooyou
      ↑ Beide targets gebruiken dezelfde CoreData store via deze group
```

### Info.plist extension — alle drie content types

```xml
NSExtensionActivationRule:
  NSExtensionActivationSupportsText: true
  NSExtensionActivationSupportsWebURLWithMaxCount: 1
  NSExtensionActivationSupportsPDFWithMaxCount: 1        ← Kassabon
NSExtensionPointIdentifier: com.apple.share-services
```

### ShareViewController.swift — content type routing

```swift
class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Task { await routeSharedContent() }
    }

    func routeSharedContent() async {
        guard let provider = extensionContext?
            .inputItems.first.flatMap({ ($0 as? NSExtensionItem)?.attachments?.first })
        else { return }

        if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
            // 🧾 AH Kassabon als PDF
            let url = try await provider.loadItem(forTypeIdentifier: UTType.pdf.identifier) as! URL
            await handleReceiptPDF(url)

        } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            // 📝 AH Recept als tekst
            let text = try await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as! String
            await handleRecipeText(text)

        } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            // 🔗 AH Recept als link
            let url = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as! URL
            await handleRecipeURL(url)
        }
    }

    // PDF → tekst extractie → Claude
    func handleReceiptPDF(_ fileURL: URL) async {
        // Optie A: PDFKit tekst extractie (snel, gratis)
        if let pdfDoc = PDFDocument(url: fileURL),
           let text = (0..<pdfDoc.pageCount)
               .compactMap({ pdfDoc.page(at: $0)?.string })
               .joined(separator: "\n").nilIfEmpty {
            let items = try await ClaudeService.shared.parseReceiptText(text)
            showReceiptConfirmation(items)

        // Optie B: PDF als base64 naar Claude (als tekst extractie faalt)
        } else if let pdfData = try? Data(contentsOf: fileURL) {
            let items = try await ClaudeService.shared.parseReceiptPDF(pdfData)
            showReceiptConfirmation(items)
        }
    }
}
```

### Claude prompt — Kassabon PDF/tekst

```swift
let receiptSystemPrompt = """
Extract all purchased food items from this Dutch Albert Heijn receipt.
Return ONLY valid JSON, no markdown.
Focus on food products only, ignore loyalty points, bags, deposits.

{
  "store": "Albert Heijn",
  "date": "YYYY-MM-DD or null",
  "items": [
    {
      "name": "string (exact product name as on receipt)",
      "quantity": number,
      "unit": "stuks|kg|liter|gram",
      "price_per_unit": number
    }
  ]
}
"""

// Voor directe PDF naar Claude API (base64):
let message = [
    "role": "user",
    "content": [
        [
            "type": "document",
            "source": [
                "type": "base64",
                "media_type": "application/pdf",
                "data": pdfData.base64EncodedString()
            ]
        ],
        ["type": "text", "text": "Extract all food items from this AH receipt. \(receiptSystemPrompt)"]
    ]
]
```

### Sheet UI na bon verwerking

```
┌─────────────────────────────────┐
│  ✕  Bon verwerkt                │
│     Albert Heijn · 26 apr       │
│                                 │
│  14 producten herkend           │
│                                 │
│  ┌──────────────────────────┐   │
│  │ ✅ AH Kwark 0% vet 500g  │   │
│  │    2×  THT: [15 mei   ▼] │   │  ← Date picker inline
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │
│  │ ✅ AH Halfvolle Melk 1L  │   │
│  │    3×  THT: [02 mei   ▼] │   │
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │
│  │ ✅ AH Granola Chocolade  │   │
│  │    1×  THT: [aug 2026 ▼] │   │
│  └──────────────────────────┘   │
│  ┌──────────────────────────┐   │
│  │ ⚠️ Libanees platbrood    │   │  ← Nieuw product, wordt aangemaakt
│  │    4×  THT: [30 apr   ▼] │   │
│  │    [Voedingswaarden →]   │   │
│  └──────────────────────────┘   │
│  ...                            │
│                                 │
│  [Skip THT]  [Alles toevoegen]  │
└─────────────────────────────────┘
```

> **UX detail:** THT is optioneel — “Skip THT” voegt alles toe zonder datum.  
> Producten die al in de DB staan worden automatisch gekoppeld.  
> Nieuwe producten worden aangemaakt met Open Food Facts lookup op naam.

### Claude prompt — recept tekst (ongewijzigd)

```swift
let recipeSystemPrompt = """
Extract all ingredients from this Dutch recipe text.
Return ONLY valid JSON, no markdown.

{
  "dish_name": "string",
  "servings": number,
  "prep_time_minutes": number,
  "calories_per_serving": number or null,
  "ingredients": [
    {
      "name": "string (Dutch name as in recipe)",
      "category": "string (generic: chicken_breast, olive_oil, tomato, etc.)",
      "amount": number,
      "unit": "gram|ml|stuks|el|tl|teen|snuf",
      "optional": false
    }
  ]
}
"""
```

### Sheet UI na ontvangen recept

```
┌─────────────────────────────────┐
│  ✕  Recept toevoegen            │
│                                 │
│  🍗 Gegrilde kip met            │
│     romaatjes-pruimsalade       │
│     4 pers · 30 min · 425 kcal  │
│                                 │
│  📅 Wanneer?                    │
│  [Vandaag ✓]  [Morgen]  [Kies] │
│                                 │
│  🕐 Welk moment?                │
│  ┌──────────┬──────────┐        │
│  │ 🌅       │ 🍎       │        │
│  │ Ontbijt  │ Snack v. │        │
│  ├──────────┼──────────┤        │
│  │ ☀️       │ 🍊       │        │
│  │ Lunch    │ Snack m. │        │
│  ├──────────┼──────────┤        │
│  │ 🌙  ✓   │ 🌟       │        │  ← Avondeten geselecteerd
│  │ Avondeten│ Snack a. │        │
│  └──────────┴──────────┘        │
│                                 │
│  👥 Personen  ← 1  2  [3]  4 → │
│                                 │
│  ─── Ingrediënten ───           │
│  ✅ Kipfilet       → AH Kipfilet│
│  ✅ Olijfolie      → AH Olijf.  │
│  ⚠️ Verse pruimen  → Niet in DB │
│                                 │
│     [Opslaan als gepland]       │
└─────────────────────────────────┘
```

-----

## 🤖 Claude API Prompts

### Maaltijd foto herkenning

```swift
"""
Analyze the food photo and return ONLY valid JSON.
Use generic lowercase ingredient categories.
Suggest the most likely meal slot based on the food type.

{
  "dish": "string",
  "confidence": 0.0-1.0,
  "suggested_slot": "breakfast|morning_snack|lunch|afternoon_snack|dinner|evening_snack",
  "ingredients": [
    { "category": "string", "confidence": 0.0-1.0, "estimated_amount_g": number }
  ]
}
"""
```

### Bon herkenning

```swift
"""
Extract all purchased food items from this Dutch receipt photo.
Return ONLY valid JSON.

{
  "store": "string",
  "date": "YYYY-MM-DD or null",
  "items": [
    { "name": "string", "quantity": number, "unit": "stuks|kg|liter", "price_per_unit": number }
  ]
}
"""
```

### Product matching logica

```swift
func matchIngredientToProduct(category: String) -> [Product] {
    productDatabase
        .filter { $0.ingredientCategories.contains(category) }
        .sorted {
            // Meest gebruikt staat bovenaan — AH Kwark 0% automatisch #1
            if $0.usageCount != $1.usageCount { return $0.usageCount > $1.usageCount }
            return ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast)
        }
}
```

-----

## 🔌 Open Food Facts API

```swift
// Barcode lookup
GET https://world.openfoodfacts.org/api/v2/product/{barcode}.json

// Naam zoeken (NL)
GET https://world.openfoodfacts.org/cgi/search.pl?
    search_terms=AH+kwark&search_simple=1&action=process&json=1&lc=nl

// Response: product_name, nutriments, image_url, brands, quantity
```

-----

## 📱 Schermen

### Tab Bar

```
🏠 Voorraad    📅 Dag    📸 Scannen    ⚙️ Instellingen
```

**Voorraad** — Koelkast / Vriezer / Kast segmenten, THT kleurcodering, swipe-to-consume.

**Dag** — De 6-slot dag view. Navigeer met swipe of datumkiezer. Gepland = blauw gestippeld. Gegeten = groen. Leeg = + knop.

**Scannen** — 4-knoppen grid: Bon foto · Maaltijd · Barcode · Handmatig. AH bon (PDF) en recepten komen binnen via Share Extension als sheet — de cameraknop is voor bons van andere winkels (Lidl, Jumbo, etc.).

**Instellingen** — Calorie + macro doelen, HealthKit toggle, notificatievoorkeuren, producten beheren.

-----

## 🔔 Notificaties

|Trigger                          |Bericht                             |Timing           |
|---------------------------------|------------------------------------|-----------------|
|Voorraad < drempel               |“Je AH Kwark is bijna op (50g over)”|Direct           |
|THT < 3 dagen                    |“Halfvolle melk verloopt overmorgen”|10:00            |
|THT verlopen                     |“AH Kwark is vandaag verlopen”      |10:00            |
|Gepland avondeten niet gemarkeerd|“Je avondeten nog niet gelogd?”     |21:00            |
|Geen log vandaag                 |“Vergeten te loggen vandaag?”       |13:00 (optioneel)|

-----

## 🚀 Bouwfasen

### Fase 1 — Fundament (Weekend 1-2)

- [ ] Xcode project (SwiftUI, CoreData, CloudKit, App Group entitlement)
- [ ] Data modellen: Product, PantryItem, MealSlot, PlannedMeal, MealLog
- [ ] Barcode scanner (AVFoundation)
- [ ] Open Food Facts API service
- [ ] Product toevoegen via barcode → voorraad

**MVP:** Producten scannen en voorraad bijhouden

-----

### Fase 1b — Share Extension + Maaltijd planning (Weekend 2-3)

- [ ] Share Extension target aanmaken + App Group data sharing
- [ ] ShareViewController: PDF (bon) + tekst (recept) + URL routing
- [ ] PDF parsing: PDFKit tekst extractie → Claude, met base64 fallback
- [ ] ClaudeService: recepttekst → JSON ingrediënten
- [ ] ClaudeService: bonnekst → JSON producten
- [ ] Slot picker UI (6 opties, visueel 2×3 grid)
- [ ] Datum picker (vandaag / morgen / kies)
- [ ] PlannedMeal opslaan via App Group → CoreData
- [ ] Dag view met 6 slots + states (leeg / gepland / gegeten)
- [ ] “Markeer als gegeten” bottom sheet

**MVP:** AH recept delen → plannen → markeren als gegeten

-----

### Fase 2 — Bon scannen + HealthKit (Weekend 3-4)

- [ ] Bon scan flow (Claude vision → receipt JSON)
- [ ] Houdbaarheidsdatum invoer per product
- [ ] Voorraad importeren vanuit bon
- [ ] HealthKitService.swift — schrijven bij “markeer als gegeten”
- [ ] HealthKit permissie onboarding flow
- [ ] Valideren: Coach Leo ziet data in Apple Health

**MVP:** Bon scannen + HealthKit sync → Coach Leo ziet voeding

-----

### Fase 3 — Maaltijd foto scannen (Weekend 5-6)

- [ ] Maaltijd foto → Claude → ingrediënt categorieën
- [ ] Product matching + bevestigingsflow
- [ ] Voorraad aftrekken na bevestiging
- [ ] Dag macro overzicht (ring of bar chart)

**MVP:** Volledige foto → calorie → voorraad → HealthKit loop

-----

### Fase 4 — Polish & TestFlight (Weekend 7-8)

- [ ] Notificaties implementeren
- [ ] Onboarding flow (eerste keer opstarten, HealthKit toestemming)
- [ ] Lege states + illustraties
- [ ] App icoon + splash screen
- [ ] TestFlight build voor Roos
- [ ] Widget: dag calorieën + volgende geplande maaltijd

-----

## 💰 Kosten schatting

|Gebruik                 |Scans/dag|Kosten/maand|
|------------------------|---------|------------|
|Licht (Iwan alleen)     |~5       |~€0.50      |
|Normaal (Iwan + Roos)   |~10      |~€1.00      |
|Intensief incl. recepten|~20      |~€2.00      |

*Recepttekst parsing (geen foto) = ~500 tokens → goedkoper dan foto scans*  
*Claude Haiku 4.5: $1/MTok input, $5/MTok output*

**Open Food Facts:** Gratis · **HealthKit:** Gratis · **Apple Developer:** €99/jaar (actief) · **CloudKit:** Inbegrepen

-----

## 🔑 Environment & Secrets

```
# Secrets.xcconfig — NOOIT committen naar GitHub
CLAUDE_API_KEY = sk-ant-...
```

```
# .gitignore
Secrets.xcconfig
DerivedData/
.DS_Store
*.xcuserstate
Fooyou.xcodeproj/xcuserdata/
```

-----

## 📚 Externe bronnen

- [Claude API docs](https://docs.anthropic.com)
- [Open Food Facts API](https://wiki.openfoodfacts.org/API)
- [HealthKit voedingsdata (HKCorrelationType.food)](https://developer.apple.com/documentation/healthkit/hkcorrelationtype)
- [Share Extension guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Share.html)
- [App Groups — data delen tussen targets](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [CoreData + CloudKit sync](https://developer.apple.com/documentation/coredata/mirroring_a_core_data_store_with_cloudkit)
- [AVFoundation barcode scanning](https://developer.apple.com/documentation/avfoundation/barcode_detection)

-----

## 👥 Gedeelde Voorraad — Architectuur

### Doel
Iwan en Roos (twee Apple IDs, één huishouden) werken allebei op dezelfde voorraad. Beiden kunnen producten toevoegen, afboeken en food logs maken.

### Oplossing: CloudKit Sharing (CKShare)

De app gebruikt al `NSPersistentCloudKitContainer`. CloudKit heeft ingebouwde ondersteuning voor het delen van data tussen verschillende Apple IDs via `CKShare` — hetzelfde mechanisme dat Apple gebruikt in Herinneringen en Notities.

**Hoe het werkt:**
```
Iwan maakt een gedeelde zone aan → genereert uitnodigingslink
Roos tikt de link → accepteert → heeft toegang tot dezelfde voorraad
Beide apparaten schrijven naar dezelfde CloudKit zone
Conflicten worden automatisch opgelost (last-write-wins per record)
```

**Implementatie (geen custom backend nodig):**
```swift
// 1. Maak een CKShare aan voor de voorraad zone
let share = CKShare(rootRecord: pantryZoneRecord)
share[CKShare.SystemFieldKey.title] = “Fooyou Voorraad”

// 2. Toon de Apple share UI
let controller = UICloudSharingController(share: share, container: CKContainer.default())
present(controller, animated: true)

// 3. Ontvanger accepteert via universele link → app opent automatisch
```

**Voordelen:**
- Geen eigen server, geen extra kosten
- End-to-end beveiligd via Apple
- Werkt offline (sync zodra verbinding terug is)
- Geen wachtwoord of code nodig — Apple ID authenticatie

**Beperkingen:**
- Werkt alleen tussen iOS-gebruikers met Apple ID
- Roos moet de uitnodiging accepteren (eenmalig)
- Conflicten bij gelijktijdig afboeken: CloudKit lost dit op via timestamp

### Alternatief: Supabase backend (indien later nodig)

Als de app ooit breder wordt (meer gebruikers, Android, web):
- Supabase met Row Level Security
- Huishoud-code of uitnodigingslink genereren
- Realtime subscriptions voor live sync

**Conclusie voor nu:** CloudKit Sharing is de juiste keuze — geen extra infra, zit al in de stack.

-----

## 🧠 Backlog

- **”Wat kan ik koken?”** — Claude suggereert recepten op basis van huidige voorraad
- **Boodschappenlijst** — automatisch op basis van lage voorraad + geplande maaltijden
- **Weekoverzicht** — calorie trends + macro gemiddelden als grafiek
- **Recepten opslaan** — eigen gerechten bewaren voor snelle herlog
- **Widget** — dag calorieën + volgende geplande maaltijd op homescreen
- **Coach Leo deep link** — tap op voedingsdata in Coach Leo → open Fooyou dag detail
- **Gedeelde voorraad** — CKShare uitnodiging in Instellingen → Roos krijgt link → zelfde CloudKit zone

-----

*Laatste update: april 2026*  
*Project: Fooyou iOS*  
*Stack: SwiftUI · CoreData · CloudKit · Claude Haiku 4.5 · Open Food Facts · HealthKit*
