// lib/core/data/learn_content.dart
//
// Static content for the Learn section.
// All 6 pillar articles — fully authored, research-based.
// No network required — fully offline readable.

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class LearnSection {
  final String heading;
  final String body;

  const LearnSection({required this.heading, required this.body});
}

class LearnArticle {
  final String id;
  final String categoryKey;     // matches diagnosis causeKey
  final String categoryLabel;   // display name for chip
  final String title;
  final String summary;         // 2-line card summary
  final String heroEmoji;
  final Color  accentColor;
  final Color  lightColor;
  final String youtubeUrl;      // opened via url_launcher
  final String youtubeTitle;    // shown on the video card
  final String deepDive;        // 400-600 word article body
  final List<LearnSection> actionableSections;
  final String researchCorner;  // expert insight paragraph

  const LearnArticle({
    required this.id,
    required this.categoryKey,
    required this.categoryLabel,
    required this.title,
    required this.summary,
    required this.heroEmoji,
    required this.accentColor,
    required this.lightColor,
    required this.youtubeUrl,
    required this.youtubeTitle,
    required this.deepDive,
    required this.actionableSections,
    required this.researchCorner,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Color palettes per category (kept consistent with app theme)
// ─────────────────────────────────────────────────────────────────────────────
const _deepGreen   = Color(0xFF2D6A4F);
const _amber       = Color(0xFFF4A22D);
const _lightAmber  = Color(0xFFFFF3CD);
const _terracotta  = Color(0xFFC1694F);
const _lightRed    = Color(0xFFFFE5E5);
const _blue        = Color(0xFF1E6A9E);
const _lightBlue   = Color(0xFFDCEEFA);
const _purple      = Color(0xFF6A2D8E);
const _lightPurple = Color(0xFFF0E6F8);
const _green       = Color(0xFF52B788);
const _lightGreen  = Color(0xFFD8F3DC);

// ─────────────────────────────────────────────────────────────────────────────
// All 6 articles
// ─────────────────────────────────────────────────────────────────────────────
final List<LearnArticle> learnArticles = [

  // ── 1. DROUGHT ─────────────────────────────────────────────────────────────
  LearnArticle(
    id:            'drought',
    categoryKey:   'drought',
    categoryLabel: 'Drought Stress',
    title:         'Surviving Drought: Protecting Your Crop When Rain Fails',
    summary:       'Learn how to read drought signals early, time your irrigation correctly, and use mulching to keep moisture in your soil longer.',
    heroEmoji:     '🏜️',
    accentColor:   _amber,
    lightColor:    _lightAmber,
    youtubeUrl:    'https://www.youtube.com/watch?v=5wR2OdW4D2g',
    youtubeTitle:  'Drip Irrigation & Drought Management for Small Farms',
    deepDive: '''
Drought stress is one of the most common and economically damaging threats facing Indian farmers, particularly during the Kharif season when monsoon failure can wipe out months of investment in a matter of weeks. Understanding what happens inside your crop during a dry period — and what you can do about it at each stage — is the difference between salvaging a partial yield and losing everything.

When soil moisture drops below a critical threshold, your crop enters "water stress." At this point, the plant closes tiny pores called stomata on its leaves to stop losing moisture through transpiration. This sounds protective, but it has a severe consequence: stomata are the same pores through which carbon dioxide enters the leaf for photosynthesis. When they close, the plant cannot produce food for itself. Growth slows, then stops. In flowering crops like cotton, groundnut, and soybean, stress during the reproductive stage causes flowers to abort — the most economically damaging event in any season.

The classic visible signs of drought stress appear in a predictable order. First, leaves begin curling inward or downward — this is the plant reducing its surface area to slow water loss. Next, the colour shifts from deep green to a dull, grey-green. Then wilting begins during the hottest part of the day, even if the plant recovers at night. Finally, leaves yellow from the margins inward, starting with older leaves at the bottom. If you see margin yellowing combined with wilting, water stress has already become severe.

The critical insight most farmers miss is that the most vulnerable growth windows are not obvious from looking at the plant. In cereals like wheat and maize, the period from flowering to grain fill is the most sensitive — a mere 7-10 days of stress here can reduce yield by 30-50%. In legumes, stress during pod formation has similar consequences. Knowing your crop's growth stage calendar and acting before these windows are reached is what separates good drought management from reactive crisis management.

The good news is that moderate drought stress, caught early, is recoverable. Crops that are re-watered within 48-72 hours of showing early wilting symptoms can fully recover their yield potential, especially if the stress occurred during vegetative growth rather than reproductive stages. The soil itself carries a memory of moisture — deep, cracked soils that dry from the surface down still hold water at root depth, and a targeted deep irrigation can pull a crop back from the brink.

Understanding the relationship between soil texture and water holding capacity is also critical. Sandy loils lose water three to four times faster than clay loams. If your field has a sandy texture, shorter, more frequent irrigations are always more effective than one large flood. Conversely, heavy clay soils retain water well but have poor aeration — over-irrigating them creates a different problem entirely.
''',
    actionableSections: [
      LearnSection(
        heading: '💧 Protective Irrigation: Timing is Everything',
        body: 'The most effective irrigation in a drought is not the biggest one — it is the one given at the right growth stage. Apply a "protective" light irrigation (roughly 25-30mm) at the first sign of wilting, always in the evening or early morning to minimise evaporation losses. Avoid irrigating during the hottest part of the afternoon — up to 40% of applied water is lost to surface evaporation before it reaches root depth. If you have only one irrigation available, save it for the flowering or pod-fill stage, as this is when water stress causes irreversible yield loss.',
      ),
      LearnSection(
        heading: '🌿 Mulching: Your Cheapest Insurance Against Drought',
        body: 'Applying a 5-8 cm layer of dry crop residue, straw, or sugarcane trash around the base of your plants reduces soil surface evaporation by up to 60% and can extend the period between irrigations by 7-10 days. Organic mulch also breaks down slowly and improves soil organic matter, meaning the benefit compounds over multiple seasons. In row crops, apply mulch along the furrows. For transplanted crops, mulch the beds but leave a 5cm gap around each stem to prevent stem rot. In the absence of crop residue, even newspaper or cardboard anchored with soil provides meaningful evaporation reduction.',
      ),
      LearnSection(
        heading: '🕳️ Soil Crack Management: Stopping Hidden Water Loss',
        body: 'Deep cracks in clay soils are a major but overlooked source of water loss. Each crack acts as a direct channel from the surface to the subsoil, bypassing the root zone entirely. When you see cracking, do not simply flood-irrigate — this wastes water and can damage root structure. Instead, apply a shallow pre-irrigation of 10-15mm first to allow the soil to swell and close the surface cracks. Then apply a deeper root-zone irrigation 12-24 hours later. This two-stage approach ensures water reaches the roots rather than draining away through the crack network.',
      ),
    ],
    researchCorner: 'Research from the Indian Council of Agricultural Research (ICAR) shows that deficit irrigation at 60-80% of crop water requirement during vegetative stages, combined with full irrigation during the reproductive stage, results in only a 10-15% yield reduction compared to fully-irrigated crops — while saving 35-40% of total water used. This "regulated deficit irrigation" strategy is increasingly recommended by KVK extension workers for water-scarce regions. ICAR also recommends the use of "stress-tolerant" varieties identified by AICRP (All India Coordinated Research Project) trials specific to each agro-climatic zone.',
  ),

  // ── 2. WATERLOGGING ────────────────────────────────────────────────────────
  LearnArticle(
    id:            'waterlogging',
    categoryKey:   'waterlogging',
    categoryLabel: 'Waterlogging',
    title:         'When Too Much Water Kills: Managing Waterlogged Fields',
    summary:       'Understand why standing water suffocates roots, how to build emergency drainage channels, and how to diagnose root health before it is too late.',
    heroEmoji:     '💧',
    accentColor:   _blue,
    lightColor:    _lightBlue,
    youtubeUrl:    'https://www.youtube.com/watch?v=bfN8u1HBWMU',
    youtubeTitle:  'Field Drainage Techniques for Indian Farmers',
    deepDive: '''
Waterlogging is the silent killer of the monsoon season. While drought stress is visible — wilting, yellowing, cracking soil — waterlogging often progresses below the surface, damaging roots before the first visible symptom appears above ground. By the time a farmer notices yellowing leaves or wilting despite wet soil, root rot may have already reached an irreversible stage.

The science is straightforward but counterintuitive: plants need oxygen at their roots, not just water. Soil is not a solid mass — it contains pore spaces that are normally filled with a mix of water and air. When the soil becomes saturated, all those air pores fill with water, and the oxygen available to roots drops to near zero within 24-48 hours. Without oxygen, root cells cannot respire, the active uptake of water and nutrients stops, and anaerobic bacteria begin breaking down root tissue — this is the origin of root rot, characterised by the distinctive blackened, foul-smelling roots that indicate severe waterlogging damage.

Different crops have very different tolerances to waterlogging. Rice, which evolved in flooded paddies, can survive submersion using specialised anatomy. But wheat, maize, soybean, cotton, and most vegetables have no such adaptation. For wheat, even 24 hours of surface waterlogging during the tillering or grain-fill stage can reduce yield by 15-20%. For soybean, 48 hours of root-zone saturation during the flowering stage can cause 40-60% yield loss through a combination of flower abort and root damage.

The first visible symptoms of waterlogging damage mimic nitrogen deficiency — a uniform yellowing of lower leaves, starting at the margins and progressing inward. This happens because one of the first casualties of root oxygen deprivation is nitrogen uptake. Roots cannot absorb nitrogen from the soil when they are not functioning, even when adequate nitrogen is present. This symptom overlap causes many farmers to apply fertiliser when the real issue is drainage — an expensive mistake that doesn't address the root cause.

One critical diagnostic test: gently pull up a wilting plant from a waterlogged area and examine the roots. Healthy roots are white or cream-coloured, firm, and have a clean smell. Waterlogging-damaged roots are brown or black, soft, and smell of decay. If you can still find some white root tips, the plant has a chance of recovery once the drainage is established. If all visible roots are black and soft, the plant will not recover regardless of what fertilisers or sprays are applied.

Another overlooked consequence of waterlogging is soil compaction. When tractors or farm workers walk on waterlogged fields, the saturated soil particles pack together, destroying the pore structure. This creates a "plough pan" — a dense layer that impedes drainage and root penetration for the next two to three seasons. Minimising traffic on wet fields is not just about avoiding stuck tractors; it is about protecting the long-term productivity of your land.
''',
    actionableSections: [
      LearnSection(
        heading: '🌊 Building Emergency Drainage Channels',
        body: 'The fastest intervention for a waterlogged field is the construction of open field drainage channels. In an acute waterlogging event, use a tractor-mounted ridger or a simple manual spade to cut furrows from the waterlogged area toward the field boundary. Furrows should be spaced 5-8 metres apart for row crops and should have a consistent downward slope of at least 0.5% (a 5cm drop over every 10 metres) to allow water to flow out. For permanent fields with recurring waterlogging, consider constructing a permanent field channel along the lowest-lying boundary. The investment typically pays back within 2-3 seasons through reduced crop loss.',
      ),
      LearnSection(
        heading: '🌱 Soil Aeration After Drainage',
        body: 'Once standing water has drained, the next priority is restoring oxygen to the root zone before secondary root rot develops. If you can access the field without compacting it, a light cultivator pass at 10-12 cm depth creates channels for air penetration. Alternatively, applying a thin layer of well-dried compost or sand on the soil surface helps re-establish the capillary structure. Do not apply any fertiliser or spray for at least 5-7 days after drainage — the recovering root system cannot absorb inputs and you risk further stressing already damaged tissue.',
      ),
      LearnSection(
        heading: '🔍 Root Health Diagnostics: The 5-Plant Test',
        body: 'Once drainage is established, conduct a systematic root health check by carefully uprooting 5 representative plants from different zones of the field (waterlogged centre, edge, and a dry reference zone). Score each plant\'s root system: white roots with no smell = healthy; brown roots with musty smell = early damage, likely recoverable; black, soft roots with foul smell = severe rot, unlikely to recover. This test takes 15 minutes and prevents wasting inputs on plants that cannot be saved. In a partially waterlogged field, use this data to decide which zones to replant versus rehabilitate.',
      ),
    ],
    researchCorner: 'Research from the Banaras Hindu University (BHU) agricultural faculty and the National Rice Research Institute (NRRI) confirms that installing field drainage before the monsoon season — even simple open channels — reduces crop loss from waterlogging events by an average of 55% in medium and heavy-textured soils. The ICAR-CSSRI (Central Soil Salinity Research Institute) has also developed guidelines for subsurface drainage design suited to the Indo-Gangetic plains, which KVK extension officers can help implement at the farm level.',
  ),

  // ── 3. PEST PRESSURE ──────────────────────────────────────────────────────
  LearnArticle(
    id:            'pest',
    categoryKey:   'pest',
    categoryLabel: 'Pest Pressure',
    title:         'Mastering Pest Scouting: Stop Losses Before They Start',
    summary:       'Discover the 10-plant scouting method, when to use pheromone traps, and how the Economic Threshold Level prevents unnecessary pesticide costs.',
    heroEmoji:     '🐛',
    accentColor:   _terracotta,
    lightColor:    _lightRed,
    youtubeUrl:    'https://www.youtube.com/watch?v=tJJpR0y5bpU',
    youtubeTitle:  'Integrated Pest Management (IPM) for Indian Crops',
    deepDive: '''
Pests can destroy a crop in 48 hours if missed. This is not an exaggeration — a single heavy infestation of fall armyworm in maize, or pod-borer in pigeon pea, can cause 70-80% yield loss within a week during peak pest pressure. Yet research consistently shows that early detection reduces pesticide costs by 40% while achieving better pest control outcomes than reactive spraying. The difference is a systematic scouting discipline.

The fundamental insight of Integrated Pest Management (IPM) — the globally accepted framework for sustainable pest control — is that not every pest sighting requires a chemical response. All field ecosystems carry background levels of pests at all times. Natural predators — ladybirds, parasitic wasps, spiders, and ground beetles — keep these populations in check under normal conditions. Spraying insecticides disrupts this biological balance, often causing a "secondary pest outbreak" where the natural enemies are eliminated faster than the pests, leading to an even worse infestation 2-3 weeks after the initial spray.

The key concept is the Economic Threshold Level (ETL) — the pest population density at which the cost of crop damage if left untreated exceeds the cost of control. Below the ETL, the economic case for spraying does not exist. Above the ETL, intervention is justified. These thresholds have been scientifically established for all major pest-crop combinations by the ICAR network, and they vary dramatically: for cotton bollworm, the ETL is 5 egg masses per 100 plants; for aphids in mustard, it is 26 aphids per plant; for stem borer in rice, it is 5% dead hearts or white ears.

Understanding what you are looking for is as important as knowing when to look. The most destructive pest stages — first and second instar larvae — are often invisible to casual observation because they are tiny, cryptic, and actively hide. A farmer walking the edge of a field and looking at the tops of plants will miss the vast majority of early infestations. Systematic underside-of-leaf examination of randomly selected plants from within the field body, not just the border rows, is the only reliable detection method.

Trap-based monitoring complements visual scouting by providing early warning before populations reach damaging levels. Pheromone traps use species-specific sex attractants to catch male moths, giving a "catch count per week" metric that predicts when egg-laying will peak in the field. Yellow sticky traps monitor sap-sucking insects like aphids and whitefly. Both trap types are inexpensive, reusable, and give data that allows a farmer to time any intervention precisely, avoiding the common trap of calendar-based spraying that wastes money and builds pesticide resistance.

The economic argument for scouting over calendar-based spraying is compelling. Studies from Punjab Agricultural University (PAU) show that IPM-following farmers apply pesticides 2.3 times fewer per season on average compared to non-IPM farmers, while achieving statistically equivalent yields. The pesticide cost saving alone — typically Rs. 2,000-5,000 per acre per season — more than offsets any scouting labour cost.
''',
    actionableSections: [
      LearnSection(
        heading: '🔎 The 10-Plant "W" Scouting Protocol',
        body: 'The single most important scouting practice is the "W" pattern: walk your field in a W-shape from corner to corner, stopping at 10 equally spaced points. At each stop, examine 1 representative plant thoroughly — not just the top surface of leaves, but the underside, the growing tip, and the stem base. Count and record the number of pest individuals and any damage signs (holes, frass, webbing, egg masses). Calculate the average across all 10 plants to get your field-level infestation count. Compare this number to the established ETL for your crop and the specific pest. This takes 15-20 minutes and provides statistically valid field-level data. Conduct this twice a week from crop establishment to harvest.',
      ),
      LearnSection(
        heading: '🪤 Setting Up and Reading Traps',
        body: 'Yellow sticky traps (for aphids, whitefly, leafhoppers) should be placed at canopy height — not above the crop, where they catch more pollinators. Place 5 traps per acre in the first scouting week, positioned at the field interior, not just borders. Record weekly catch counts. A sudden doubling or tripling of weekly catches is your early warning signal. Pheromone traps for specific moths (Helicoverpa, Fall Armyworm, Spodoptera) should be installed as per the pheromone manufacturer\'s instructions — typically 15-20 traps per hectare. Replace the lure every 3-4 weeks as the pheromone degrades. A catch threshold of 8-10 moths per trap per night signals the need for increased vigilance and scouting frequency.',
      ),
      LearnSection(
        heading: '📊 Economic Threshold Level (ETL) Decision Making',
        body: 'Before any pesticide purchase, compare your scouting count to the ETL. Key ETLs for common Indian crops: Rice leaf folder — 2 folded leaves per tiller; Cotton whitefly — 15 per leaf; Cotton bollworm — 8 larvae per 100 plants; Soybean girdle beetle — 2 per plant; Maize fall armyworm — 20% plants with fresh damage. If your count is below the ETL, do not spray — you are investing in pesticides that are not needed. If above ETL, select the most targeted pesticide registered for that specific pest-crop combination. Broad-spectrum sprays should be the last resort, not the first response, as they destroy your field\'s natural enemy population.',
      ),
    ],
    researchCorner: 'The National Institute of Plant Health Management (NIPHM) and ICAR\'s Directorate of Biological Control have documented that IPM-based farmers in Andhra Pradesh, Maharashtra, and Punjab reduced pesticide expenditure by Rs. 3,200 per acre on average while achieving equivalent or superior yields compared to calendar-spray farmers, across a 5-year study. The technology is proven — the gap is adoption. Contact your nearest KVK (Krishi Vigyan Kendra) for region-specific ETL tables and free starter pheromone traps under the government\'s IPM programme.',
  ),

  // ── 4. FUNGAL DISEASE ─────────────────────────────────────────────────────
  LearnArticle(
    id:            'fungal',
    categoryKey:   'fungal',
    categoryLabel: 'Fungal Disease',
    title:         'Beating Fungal Disease: Airflow, Sanitation, and Smart Spraying',
    summary:       'Learn why fungal diseases spread exponentially in humid conditions, how field sanitation halts the epidemic, and which fungicide class matches your specific disease.',
    heroEmoji:     '🍂',
    accentColor:   _purple,
    lightColor:    _lightPurple,
    youtubeUrl:    'https://www.youtube.com/watch?v=RvjOF5kApKI',
    youtubeTitle:  'Identifying and Managing Common Fungal Diseases in Crops',
    deepDive: '''
Fungal diseases operate by a fundamentally different mechanism to pest damage, and understanding this mechanism completely changes how you should respond to them. While insects physically consume crop tissue, fungi invade it — using thread-like structures called hyphae to penetrate leaf cells, extract nutrients, and produce spores that spread to neighbouring plants. By the time you see the first lesion, the fungus has typically been growing in the tissue for 5-10 days, and thousands of spores are already airborne.

This "latent period" — the gap between infection and visible symptom — is the central challenge of fungal disease management. When a farmer sees the first brown spot or white powder and applies a fungicide, they are already behind the epidemic curve. The lesion you can see represents the tip of the iceberg; many nearby plants will already be infected but showing no symptoms yet. This is why fungicide timing is everything — the best fungicides applied at the wrong time perform no better than water.

The disease triangle is the foundational concept: a fungal epidemic requires three factors simultaneously — a susceptible host plant, a viable pathogen (fungal spores), and a favourable environment (typically high humidity, moderate temperature, and leaf wetness). Remove any one corner of the triangle and the disease cannot spread. This is why cultural practices — manipulating the environment and reducing pathogen inoculum — are so powerful and why they complement fungicide use rather than replace it.

The environmental factor is the most actionable. Most destructive fungal diseases require free moisture on the leaf surface for spore germination and infection. This is why high-humidity nights following warm days create explosive epidemic conditions. Practices that reduce leaf wetness duration — wider plant spacing, avoiding evening irrigation, removing canopy obstructions — directly attack the disease\'s most critical requirement.

Different fungal diseases require different identification and response approaches. Powdery mildew (white powdery coating, typically on upper leaf surfaces) is caused by obligate biotrophs that grow on but not inside leaf cells — these respond well to sulfur-based fungicides and are worsened by high nitrogen application. Rust diseases (orange or brown pustules on the underside of leaves) spread through airborne urediniospores that can travel thousands of kilometres on the wind, meaning an outbreak in your field may have originated far away. Blast diseases (eye-shaped lesions with grey centres) of rice and wheat are among the most devastating yield losses in South Asia and require systemic fungicides as soon as the first lesions appear.

The key principle underlying all fungal disease management is that protectant fungicide applications — applied before infection occurs — are always more effective than curative applications after symptoms appear. A farmer who monitors weather forecasts for humid, still conditions and applies a registered protectant fungicide 2-3 days before a high-risk period will consistently outperform one who waits for visible symptoms.
''',
    actionableSections: [
      LearnSection(
        heading: '💨 Airflow Optimisation: Your First Line of Defence',
        body: 'High humidity at the crop canopy level is the single most important driver of fungal disease spread. Dense plant canopies create stagnant, humid microclimates where dew persists for hours after sunrise. In row crops like soybean, chilli, and tomato, reducing plant density by 10-15% below the recommended maximum during high-disease-risk seasons demonstrably reduces disease pressure. Orienting rows along the prevailing wind direction maximises airflow. In orchards and vegetable crops, selective pruning of inner canopy growth opens airflow channels. Avoid overhead irrigation during evening hours — the leaf wetness from evening irrigation persists through the night, exactly the high-humidity window when fungal spores germinate.',
      ),
      LearnSection(
        heading: '🧹 Sanitation: Removing the Pathogen Source',
        body: 'Infected plant material in or near your field is the primary inoculum source for the next disease cycle. Remove infected leaves as soon as you identify them — do not leave them on the soil surface where spores continue to spread. For soil-borne diseases (damping-off, fusarium wilt, sclerotinia), remove entire infected plants including the root ball, place them in bags, and remove from the field. Do not compost infected material — many fungal pathogens survive composting temperatures. Between seasons, deep ploughing buries infected stubble below the viable zone for most fungal spores. Crop rotation with a non-host crop for at least one season breaks the disease cycle for soil-borne pathogens.',
      ),
      LearnSection(
        heading: '🧪 Fungicide Matching: Class Matters More Than Brand',
        body: 'Not all fungicides work on all diseases — selecting the wrong class is one of the most common and costly mistakes in disease management. Powdery mildew: sulfur-based (Wettable Sulfur 80%) or DMI fungicides (propiconazole, hexaconazole). Downy mildew and late blight: mancozeb or metalaxyl+mancozeb combinations. Rusts: triazole fungicides (tebuconazole, propiconazole). Rice blast: tricyclazole or isoprothiolane — apply at neck emergence. Botrytis (grey mold): iprodione or boscalid. Always check that the fungicide is registered for your specific crop — crop registration matters for both efficacy and residue compliance. Alternate between fungicide classes each spray to prevent resistance development.',
      ),
    ],
    researchCorner: 'Research from the All India Coordinated Research Project on Plant Disease (AICRPPD) and the Indian Institute of Wheat & Barley Research (IIWBR) consistently shows that in high-disease-pressure years, a single well-timed protectant fungicide application at the correct growth stage (flag leaf emergence for wheat blast, panicle initiation for rice neck blast) provides 85-90% of the yield protection achievable from a full 3-spray programme, at roughly one-third the cost. The critical variable is timing, not frequency.',
  ),

  // ── 5. HEAT STRESS ─────────────────────────────────────────────────────────
  LearnArticle(
    id:            'heat',
    categoryKey:   'heat',
    categoryLabel: 'Heat Stress',
    title:         'Protecting Crops from Heat: Irrigation Timing, Pollination, and Shade',
    summary:       'High temperatures damage pollen and disrupt photosynthesis. Find out how pre-heat irrigation, shade netting for nurseries, and timing changes can protect your yield.',
    heroEmoji:     '🌡️',
    accentColor:   Color(0xFFE05A1A),
    lightColor:    Color(0xFFFDE9DC),
    youtubeUrl:    'https://www.youtube.com/watch?v=kJd7x1dQSWw',
    youtubeTitle:  'Heat Stress in Crops: Symptoms and Field Management',
    deepDive: '''
Heat stress is becoming one of the fastest-growing threats to Indian agriculture as climate patterns shift. Temperatures that were once rare — sustained maximums above 40°C for multiple consecutive days — are now a regular feature of the late Rabi and early Kharif seasons in central and northern India. What distinguishes heat stress from other abiotic stresses is how rapidly it causes irreversible damage: at 42°C, pollen viability in wheat drops to near zero within 4-6 hours, meaning a single hot afternoon at flowering can sterilise an entire crop's reproductive potential.

The biology of heat stress operates through two primary mechanisms. The first is protein denaturation — the unfolding of the enzymes that drive photosynthesis, cellular respiration, and pollen development. Above 40°C, these proteins begin losing their functional shape, and above 45°C the damage becomes rapid and widespread. The second mechanism is disruption of the cell membrane — the outer boundary of every plant cell — which becomes "leaky" at high temperatures, causing electrolytes to escape and disrupting the electrochemical gradients that power water and nutrient uptake.

The crop's visible responses to heat stress reflect these internal disruptions. Leaf scorch — brown, papery margins appearing on the tips and edges of leaves — is caused by local dehydration as the leaf surface loses water faster than the damaged root system can replace it. Flower drop occurs because pollen tubes, which must grow rapidly through the pistil for fertilisation to occur, are extremely temperature-sensitive. In tomatoes, consistent temperatures above 35°C cause complete fruit set failure. In wheat, hot dry winds (locally called "loo") during grain fill cause direct shrivelling of the developing grain, reducing both yield and quality.

One frequently overlooked aspect of heat stress is its interaction with soil moisture. A crop under heat stress at adequate soil moisture cools itself through transpiration — the evaporation of water from leaf surfaces, which can reduce the leaf temperature by 3-5°C below air temperature. A crop under simultaneous heat and water stress loses this cooling mechanism entirely, causing its internal temperature to exceed even air temperature. This is why irrigation during heat events is not just about water supply — it is about activating the crop's own cooling system.

The timing of heat damage is as important as its intensity. Heat stress during pollination and early grain fill causes the most economically significant losses. In wheat, this is typically the 2-week window around heading (Zadoks stage 55-75). In maize, it is the 2 weeks around silking. In soybean and chickpea, it is the pod-initiation to early pod-fill window. Knowing these windows precisely for your crop, and planning a protective irrigation if a heat event is forecast during them, is the single highest-return action a farmer can take during a heat-prone season.
''',
    actionableSections: [
      LearnSection(
        heading: '💦 Pre-Heat Irrigation: Cooling from the Ground Up',
        body: 'Apply a light irrigation (20-25mm) in the evening before a forecast high-temperature day (above 38°C maximum). This serves three functions simultaneously: it ensures adequate soil moisture so the crop can transpire freely and maintain its internal temperature through evaporative cooling; it raises the field\'s relative humidity overnight, protecting sensitive pollen from desiccation; and it ensures that the soil surface is moist at sunrise, delaying the point at which soil temperature rises to stress-inducing levels. If you have no weather forecast access, use the rule of thumb that a maximum temperature above 38°C with low humidity and a northwesterly wind (in north India) is a classic heat-stress scenario requiring protective irrigation.',
      ),
      LearnSection(
        heading: '🌸 Pollination Protection: The Critical 2-Week Window',
        body: 'During the 2-week flowering period of any grain or legume crop, reduce any additional stresses to the absolute minimum. Do not apply herbicides or heavy pesticide loads during this period — both can interfere with pollen viability and bee activity. If you have the means, apply foliar potassium (0.5% potassium nitrate spray) during the evening 2-3 days before forecast high temperatures — potassium improves the plant\'s cellular heat-tolerance mechanisms. Maintain soil moisture at or above 70% of field capacity throughout flowering. In vegetables grown in the high-heat season (summer tomatoes, capsicum, brinjal), removing flowers that open on days above 38°C and allowing the plant to set fruit on cooler days is a practical management option for small plots.',
      ),
      LearnSection(
        heading: '🌿 Shade Netting for Nurseries and High-Value Crops',
        body: 'For nurseries raising seedlings for transplanting (tomato, chilli, onion, paddy), a 50% shade net reduces the temperature under the net by 4-6°C and significantly improves seedling survival and quality during hot-weather sowing windows. The investment for a 100-square-metre nursery shade structure is approximately Rs. 2,000-3,500 and lasts 5-7 seasons. For high-value vegetable crops in the field, a 30-35% shade net covering — installed at 1.5-2 metres height above the crop canopy — is economically justified. The net reduces leaf temperature, slows transpiration, and protects flowers from heat sterilisation, typically increasing marketable yield by 20-35% in heat-prone summer growing seasons.',
      ),
    ],
    researchCorner: 'ICAR\'s wheat research network has documented that terminal heat stress — high temperatures during the last 3 weeks before harvest — is responsible for 15-20% average yield losses in north Indian wheat every year where the Rabi season extends into April. Studies from the Indian Agricultural Research Institute (IARI) show that the combination of pre-heading protective irrigation plus selection of heat-tolerant varieties (such as HD 2967 or K 307 for the Indo-Gangetic plains) reduces this heat loss by 60-70% without any other change in management.',
  ),

  // ── 6. NUTRIENT DEFICIENCY ─────────────────────────────────────────────────
  LearnArticle(
    id:            'nutrient',
    categoryKey:   'nutrient',
    categoryLabel: 'Nutrient Deficiency',
    title:         'Reading Your Crop\'s Hunger Signs: Nutrient Deficiency Diagnosis',
    summary:       'Yellow leaves, purple patches, and poor growth are your crop talking. Learn to identify nitrogen vs phosphorus deficiency and apply the right fix at the right time.',
    heroEmoji:     '🟡',
    accentColor:   _green,
    lightColor:    _lightGreen,
    youtubeUrl:    'https://www.youtube.com/watch?v=oHFiXeKvLkM',
    youtubeTitle:  'Identifying Nutrient Deficiencies in Crops: Visual Guide',
    deepDive: '''
Nutrient deficiency diagnosis is one of the most valuable skills a farmer can develop, because it turns visible crop symptoms into actionable information. Unlike pest damage or disease lesions, nutrient deficiency symptoms follow very specific, predictable patterns that reflect the chemistry of how plants move and use different elements. Once you understand these patterns, you can often identify the deficient nutrient from a field observation alone — saving the time and cost of waiting for a soil test result when a crop is actively struggling.

The most important organising principle is nutrient mobility: some nutrients (nitrogen, phosphorus, potassium, magnesium) can be moved within the plant from older to younger tissues when supply is limited. Others (calcium, boron, iron, manganese) cannot move once deposited in a tissue. This single fact determines whether a deficiency appears first in old leaves (bottom of the plant) or new leaves (growing tip), which is the primary diagnostic clue in field observation.

Nitrogen deficiency is the most common and economically significant nutrient problem in Indian agriculture. It begins with the oldest, lowest leaves turning uniformly pale yellow — starting at the tip and progressing toward the base of the leaf. Unlike many diseases, nitrogen deficiency yellowing is perfectly uniform, with no spots, blotches, or margin patterns. As the deficiency progresses, the yellowing moves up the plant, with the lower leaves dropping entirely. The whole plant takes on a stunted, pale appearance and growth slows dramatically. In cereals, tillering is reduced and internodes are short. Critically, nitrogen deficiency symptoms can be difficult to distinguish from waterlogging damage — both cause lower-leaf yellowing — making accurate diagnosis dependent on examining the root and soil conditions simultaneously.

Phosphorus deficiency is less commonly recognised in the field but causes severe yield losses, particularly at early growth stages when the seedling root system is not yet developed enough to explore a large soil volume. The classic symptom is purple or red-purple discolouration of the underside of leaves and stems — caused by accumulation of anthocyanin pigments when phosphorus is unavailable. This is most visible in maize, sorghum, and tomato seedlings. In older plants, phosphorus deficiency causes dark green, dull-coloured leaves (as chlorophyll concentration increases to compensate for reduced growth) and poor root development. The most vulnerable stage is germination to 3-4 leaf stage — phosphorus banding at sowing is far more effective than later application because phosphorus moves very little in the soil.

Potassium deficiency causes marginal leaf scorch — the tips and edges of leaves turn brown and crisp, progressing inward. This is often confused with drought stress or salt damage. The key distinction is that potassium deficiency scorch typically affects middle-aged leaves first (the oldest leaves at the very bottom may still be green if deficiency is moderate), while drought damage affects the youngest, most exposed leaves most severely. Potassium is critical for grain fill and fruit quality — a potassium-deficient crop may show adequate vegetative growth but produce shrunken, poor-quality grain or fruit at harvest.

Micronutrient deficiencies — zinc, iron, boron, manganese — have become increasingly common in intensively farmed Indian soils following decades of NPK-only fertilisation. Zinc deficiency affects over 50% of Indian farmland and is characterised by small, striped leaves (interveinal chlorosis) in young tissue, stunted growth, and reduced grain set. Iron deficiency produces a vivid pattern of yellow stripes between green veins on the youngest leaves. Both are commonly worsened by high soil pH, which locks these micronutrients into unavailable forms even when they are present in adequate total quantities.
''',
    actionableSections: [
      LearnSection(
        heading: '🔬 Nitrogen vs Phosphorus: Getting the Diagnosis Right',
        body: 'When you see yellowing in young plants, the two most important questions to ask are: (1) Which leaves are affected — old and lower, or new and upper? (2) What is the colour pattern — uniform yellow, or purple-tinged? Nitrogen deficiency causes uniform yellowing starting in the oldest, lowest leaves and moving upward. Phosphorus deficiency causes purple-red discolouration of undersides of leaves and stems, especially in cold or wet soil conditions that reduce root activity. If you see both symptoms together — yellow lower leaves plus purple stems — the plant is severely stressed and may have a combined deficiency plus root dysfunction. In this case, test soil pH first: if above 7.5, neither nitrogen nor phosphorus applied to the soil surface may be absorbed effectively.',
      ),
      LearnSection(
        heading: '⚖️ Balanced NPK: Why Ratio Matters More Than Total Quantity',
        body: 'The single most common fertiliser mistake in Indian farming is applying excessive nitrogen without adequate phosphorus and potassium. High-nitrogen, low-potassium crops produce lush vegetative growth that is highly susceptible to lodging, pest attack, and fungal disease. The correct approach is to follow the soil test recommendation or, in the absence of a test, apply the recommended NPK ratio for your crop type: for cereals, a 4:2:1 (N:P:K) ratio; for legumes, a 1:2:1 ratio (legumes fix their own nitrogen but are hungry for P and K); for vegetables, a balanced 1:1:1 to 1:2:2 ratio depending on stage. Applying all phosphorus and potassium at sowing is more efficient than split applications because both nutrients move poorly in soil.',
      ),
      LearnSection(
        heading: '💧 Moisture and Nutrient Synergy: Why Water Comes First',
        body: 'One of the most misunderstood relationships in crop nutrition is that fertiliser can only be absorbed when adequate soil moisture is present. Nutrients in the soil move to roots primarily through two mechanisms: mass flow (dissolved in water moving to the root) and diffusion (short-distance movement through soil water films). In dry soil, both processes essentially stop — fertiliser applied to dry soil is of no value to the crop, and may in fact cause root burn if it contacts dry root tissue. Before applying any nutrient correction — particularly during a season with erratic rainfall — always check that the root zone has at least 50% of field-capacity moisture. In practice, this means ensuring a light irrigation the day before or after any fertiliser application.',
      ),
    ],
    researchCorner: 'A National survey by the Indian Council of Fertiliser Research and the Indian Institute of Soil Science (IISS, Bhopal) found that over 60% of Indian farmland is now deficient in zinc, 41% is deficient in boron, and 33% is deficient in sulphur — all micronutrients that are not included in standard NPK fertilisation programmes. The same study showed that a single application of zinc sulphate (25 kg/ha) in zinc-deficient soils increased yield by an average of 18% across all crop types tested — making targeted micronutrient supplementation one of the highest return-on-investment practices available to Indian farmers.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns all unique category labels for chip filter
List<String> get learnCategories {
  final labels = learnArticles.map((a) => a.categoryLabel).toSet().toList();
  return labels;
}

/// Find article by id
LearnArticle? articleById(String id) {
  try {
    return learnArticles.firstWhere((a) => a.id == id);
  } catch (_) {
    return null;
  }
}