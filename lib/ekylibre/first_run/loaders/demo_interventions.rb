# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :demo_interventions do |first_run|

  if Preference.get!(:demo, false, :boolean).value
    # interventions for all poaceae
    autumn_sowables = [:poa, :hordeum_hibernum, :secale, :triticosecale, :triticum, :brassica_napus, :pisum_hibernum].collect do |n|
      Nomen::Varieties[n]
    end

    spring_sowables = [:hordeum_vernum, :pisum_vernum, :helianthus].collect do |n|
      Nomen::Varieties[n]
    end

    later_spring_sowables = [:zea].collect do |n|
      Nomen::Varieties[n]
    end

    GC.start

    first_run.count :cultural_interventions do |w|
      workers = Worker.all
      products = {
        manure: Product.where(variety: :manure).can('fertilize').all,
        tractor: { spreader: Product.can('tow(spreader)').all,
                   plower: Product.can('tow(plower)').all,
                   sower: Product.can('tow(sower)').all,
                   catcher: Product.can('catch').all },
        spreader: Product.can('spread(preparation)').all,
        plow: Product.can('plow').all,
        sow: Product.can('sow').all,
        sprayer: Product.can('spray').all,
        fertilizer: Product.where(variety: :preparation).can('fertilize').all,
        plant_medicine: Product.where(variety: :preparation).can('care(plant)').all,
      }
      Production.joins(:variant,:activity,:campaign).find_each do |production|
        next unless production.active?
        variety = Nomen::Varieties[production.variant.variety]
        if autumn_sowables.detect{|v| variety <= v}
          year = production.campaign.name.to_i
          Ekylibre::FirstRun::Booker.production = production
          production.supports.joins(:storage,:activity).find_each do |support|
            next unless support.active?
            land_parcel = support.storage
            next unless area = land_parcel.shape_area
            coeff = (area.to_s.to_f / 10000.0) / 6.0
            # 7.99 -> 20.11 -> 40.21

            # Organic Fertilizing  01-09-N-1 -> 30-09-N-1
            Ekylibre::FirstRun::Booker.intervene(:organic_fertilizing, year - 1, 9, 1, 0.96 * coeff, support: support) do |i|
              i.add_cast(reference_name: 'manure',      actor: products[:manure].sample)
              i.add_cast(reference_name: 'manure_to_spread', population: 0.2 + 4 * coeff)
              i.add_cast(reference_name: 'spreader',    actor: products[:spreader].sample)
              i.add_cast(reference_name: 'driver',      actor: workers.sample)
              i.add_cast(reference_name: 'tractor',     actor: products[:tractor][:spreader].sample)
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
            end

            # Plowing 15-09-N -> 15-10-N
            Ekylibre::FirstRun::Booker.intervene(:plowing, year - 1, 9, 15, 9.78 * coeff, support: support, parameters: {readings: {"base-plowing-0-500-1" => "plowed"}}) do |i|
              i.add_cast(reference_name: 'driver',  actor: workers.sample)
              i.add_cast(reference_name: 'tractor', actor: products[:tractor][:plower].sample)
              i.add_cast(reference_name: 'plow',    actor: products[:plow].sample)
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
            end

            # Sowing 15-10-N -> 30-10-N
            int = Ekylibre::FirstRun::Booker.intervene(:sowing, year - 1, 10, 15, 6.92 * coeff, range: 15, support: support, parameters: {readings: {"base-sowing-0-750-2" => 2000000 + rand(250000)}}) do |i|
              i.add_cast(reference_name: 'seeds',        actor: i.find(Product, variety: :seed, derivative_of: variety.name, can: "grow"))
              i.add_cast(reference_name: 'seeds_to_sow', population: rand(5) + 1)
              i.add_cast(reference_name: 'sower',        actor: products[:sow].sample)
              i.add_cast(reference_name: 'driver',       actor: workers.sample)
              i.add_cast(reference_name: 'tractor',      actor: products[:tractor][:sower].sample)
              i.add_cast(reference_name: 'land_parcel',  actor: land_parcel)
              i.add_cast(reference_name: 'cultivation',  variant: ProductNatureVariant.find_or_import!(variety.name).first, population: (area.to_s.to_f / 10000.0), shape: land_parcel.shape)
            end


            # Fertilizing  01-03-M -> 31-03-M
            Ekylibre::FirstRun::Booker.intervene(:mineral_fertilizing, year, 3, 1, 0.96 * coeff, support: support) do |i|
              i.add_cast(reference_name: 'fertilizer',  actor: products[:fertilizer].sample)
              i.add_cast(reference_name: 'fertilizer_to_spread', population: 0.4 + coeff * rand(0.6))
              i.add_cast(reference_name: 'spreader',    actor: products[:spreader].sample)
              i.add_cast(reference_name: 'driver',      actor: workers.sample)
              i.add_cast(reference_name: 'tractor',     actor: products[:tractor][:spreader].sample)
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
            end

            if w.count.modulo(3).zero? # AND NOT prairie
              cultivation = int.casts.find_by(reference_name: 'cultivation').actor
              # Treatment herbicide 01-04 30-04
              Ekylibre::FirstRun::Booker.intervene(:spraying_on_cultivation, year, 4, 1, 1.07 * coeff, support: support) do |i|
                i.add_cast(reference_name: 'plant_medicine', actor: products[:plant_medicine].sample)
                i.add_cast(reference_name: 'plant_medicine_to_spray', population: 0.18 + 0.9 * coeff)
                i.add_cast(reference_name: 'sprayer',  actor: products[:sprayer].sample)
                i.add_cast(reference_name: 'driver',   actor: workers.sample)
                i.add_cast(reference_name: 'tractor',  actor: products[:tractor][:catcher].sample)
                i.add_cast(reference_name: 'cultivation', actor: cultivation)
              end
            end
            w.check_point
          end
        end
      end
    end
    GC.start

    first_run.count :zea_cultural_interventions do |w|
      workers = Worker.all
      products = {
        tractor: { spreader: Product.can('tow(spreader)').all,
                   plower: Product.can('tow(plower)').all,
                   sower: Product.can('tow(sower)').all,
                   equipment: Product.can('tow(equipment)').all,
                   catcher: Product.can('catch').all },
        spreader: Product.can('spread(preparation)').all,
        plow: Product.can('plow').all,
        sprayer: Product.can('spray').all,
        fertilizer: Product.where(variety: :preparation).can('fertilize').all,
        plant_medicine: Product.where(variety: :preparation).can('care(plant), kill(plant)').all,
        insecticide: Product.where(variety: :preparation).can('kill(insecta)').all,
        molluscicide: Product.where(variety: :preparation).can('kill(mollusca)').all,
      }
      equipments = {
        sower: Equipment.can('spread(preparation), sow, spray').all,
        hoe: Equipment.can('hoe').all
      }
      Production.joins(:variant,:activity,:campaign).find_each do |production|
        next unless production.active?
        variety = Nomen::Varieties[production.variant.variety]
        if later_spring_sowables.detect{|v| variety <= v}
          year = production.campaign.name.to_i
          Ekylibre::FirstRun::Booker.production = production
          production.supports.joins(:activity,:storage).find_each do |support|
            next unless support.active?
            land_parcel = support.storage
            next unless area = land_parcel.shape_area
            coeff = (area.to_s.to_f / 10000.0) / 6.0

            # Plowing 15-03-N -> 15-04-N
            Ekylibre::FirstRun::Booker.intervene(:plowing, year, 4, 15, 9.78 * coeff, support: support, parameters: {readings: {"base-plowing-0-500-1" => "plowed"}}) do |i|
              i.add_cast(reference_name: 'driver',  actor: workers.sample)
              i.add_cast(reference_name: 'tractor', actor: products[:tractor][:plower].sample)
              i.add_cast(reference_name: 'plow',    actor: products[:plow].sample)
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
            end

            # Sowing 15-04-N -> 30-05-N
            int = Ekylibre::FirstRun::Booker.intervene(:all_in_one_sowing, year, 5, 2, 6.92 * coeff, range: 15, support: support, parameters: {readings: {"base-all_in_one_sowing-0-1200-2" => 80000 + rand(10000)}}) do |i|
              i.add_cast(reference_name: 'seeds',        actor: i.find(Product, variety: :seed, derivative_of: variety.name, can: "grow"))
              i.add_cast(reference_name: 'seeds_to_sow', population: (rand(4) + 6) * coeff)

              i.add_cast(reference_name: 'fertilizer',   actor: products[:fertilizer].sample)
              i.add_cast(reference_name: 'fertilizer_to_spread', population: (rand(0.2) + 1) * coeff)
              i.add_cast(reference_name: 'insecticide',   actor: products[:insecticide].sample)
              i.add_cast(reference_name: 'insecticide_to_input', population: (rand(0.2) + 1) * coeff)
              i.add_cast(reference_name: 'molluscicide',   actor: products[:molluscicide].sample)
              i.add_cast(reference_name: 'molluscicide_to_input', population: (rand(0.2) + 1) * coeff)
              i.add_cast(reference_name: 'sower',        actor: equipments[:sower].sample)
              i.add_cast(reference_name: 'driver',       actor: workers.sample)
              i.add_cast(reference_name: 'tractor',      actor: products[:tractor][:sower].sample)
              i.add_cast(reference_name: 'land_parcel',  actor: land_parcel)
              i.add_cast(reference_name: 'cultivation',  variant: ProductNatureVariant.find_or_import!(variety.name).first, population: (area.to_s.to_f / 10000.0), shape: land_parcel.shape)
            end

            # Fertilizing  01-05-M -> 15-06-M
            Ekylibre::FirstRun::Booker.intervene(:mineral_fertilizing, year, 5, 25, 0.96 * coeff, support: support) do |i|
              i.add_cast(reference_name: 'fertilizer',  actor: products[:fertilizer].sample)
              i.add_cast(reference_name: 'fertilizer_to_spread', population: 0.4 + coeff * rand(0.6))
              i.add_cast(reference_name: 'spreader',    actor: products[:spreader].sample)
              i.add_cast(reference_name: 'driver',      actor: workers.sample)
              i.add_cast(reference_name: 'tractor',     actor: products[:tractor][:spreader].sample)
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
            end

            if w.count.modulo(3).zero?
              cultivation = int.casts.find_by(reference_name: 'cultivation').actor
              # Treatment herbicide 01-04 30-04
              Ekylibre::FirstRun::Booker.intervene(:spraying_on_cultivation, year, 5, 27, 1.07 * coeff, support: support) do |i|
                i.add_cast(reference_name: 'plant_medicine', actor: products[:plant_medicine].sample)
                i.add_cast(reference_name: 'plant_medicine_to_spray', population: 0.18 + 0.9 * coeff)
                i.add_cast(reference_name: 'sprayer',  actor: products[:sprayer].sample)
                i.add_cast(reference_name: 'driver',   actor: workers.sample)
                i.add_cast(reference_name: 'tractor',  actor: products[:tractor][:catcher].sample)
                i.add_cast(reference_name: 'cultivation', actor: cultivation)
              end
            end

            # Hoeing  01-06-M -> 30-07-M
            Ekylibre::FirstRun::Booker.intervene(:hoeing, year, 6, 20, 3 * coeff, support: support, parameters: {readings: {"base-hoeing-0-500-1" => "covered"}}) do |i|
              i.add_cast(reference_name: 'cultivator',  actor: equipments[:hoe].sample)
              i.add_cast(reference_name: 'driver',      actor: workers.sample)
              i.add_cast(reference_name: 'tractor',     actor: products[:tractor][:equipment].sample)
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
            end
            w.check_point
          end
        end
      end
    end


    first_run.count :irrigation_interventions do |w|
      a = Activity.of_families(:maize_crops)
      Production.of_activities(a).joins(:activity,:campaign).find_each do |production|
        next unless production.active?
        year = production.campaign.name.to_i
        Ekylibre::FirstRun::Booker.production = production
        production.supports.joins(:storage,:activity).where(irrigated: true).find_each do |support|
          next unless support.active?
          land_parcel = support.storage
          next unless area = land_parcel.shape_area
          coeff = (area.to_s.to_f / 10000.0) / 6.0

          if sowing_intervention = support.interventions.of_nature(:sowing).reorder(:started_at).last
            cultivation = sowing_intervention.casts.find_by(reference_name: 'cultivation').actor
            # Watering  15-05-M -> 31-08-M
            Ekylibre::FirstRun::Booker.intervene(:watering, year, 7, 15, 0.96 * coeff, support: support) do |i|
              i.add_cast(reference_name: 'water',      actor: i.find(Product, variety: :water))
              i.add_cast(reference_name: 'water_to_spread', population: 200 * coeff)
              i.add_cast(reference_name: 'spreader',    actor: i.find(Product, can: "spread(water)"))
              i.add_cast(reference_name: 'driver',      actor: i.find(Worker))
              i.add_cast(reference_name: 'land_parcel', actor: land_parcel)
              i.add_cast(reference_name: 'cultivation', actor: cultivation)
            end
          end
          w.check_point
        end
      end
    end

    # interventions for grass
    first_run.count :grass_interventions do |w|
      Production.joins(:variant,:activity,:campaign).find_each do |production|
        next unless production.active?
        variety = Nomen::Varieties[production.variant.variety]
        next unless variety <= :poa
        year = production.campaign.name.to_i
        Ekylibre::FirstRun::Booker.production = production
        production.supports.joins(:storage,:activity).find_each do |support|
          next unless support.active?
          land_parcel = support.storage
          next unless area = land_parcel.shape_area
          coeff = (area.to_s.to_f / 10000.0) / 6.0
          bob = nil
          sowing = support.interventions.where(reference_name: "sowing").where("started_at < ?", Date.civil(year, 6, 6)).order("stopped_at DESC").first
          if cultivation = sowing.casts.find_by(reference_name: 'cultivation').actor rescue nil
            int = Ekylibre::FirstRun::Booker.intervene(:plant_mowing, year, 6, 6, 2.8 * coeff, support: support) do |i|
              bob = i.find(Worker)
              i.add_cast(reference_name: 'mower_driver', actor: bob)
              i.add_cast(reference_name: 'tractor',      actor: i.find(Product, can: "tow(mower)"))
              i.add_cast(reference_name: 'mower',        actor: i.find(Product, can: "mow"))
              i.add_cast(reference_name: 'cultivation',  actor: cultivation)
              i.add_cast(reference_name: 'straw', population: 1.5 * coeff, variant: ProductNatureVariant.find_or_import!(:straw, derivative_of: cultivation.variety).first)
            end

            straw = int.casts.find_by(reference_name: 'straw').actor
            Ekylibre::FirstRun::Booker.intervene(:straw_bunching, year, 6, 20, 3.13 * coeff, support: support) do |i|
              i.add_cast(reference_name: 'tractor',        actor: i.find(Product, can: "tow(baler)"))
              i.add_cast(reference_name: 'baler_driver',   actor: i.find(bob.others))
              i.add_cast(reference_name: 'baler',          actor: i.find(Product, can: "bunch"))
              i.add_cast(reference_name: 'straw_to_bunch', actor: straw)
              i.add_cast(reference_name: 'straw_bales', population: 1.5 * coeff, variant: ProductNatureVariant.import_from_nomenclature(cultivation.variety.to_s == 'triticum_durum' ? :hard_wheat_straw_bales : :wheat_straw_bales))
            end
          end
          w.check_point
        end
      end
    end

    # interventions for cereals
    first_run.count :cereals_interventions do |w|
      Production.joins(:variant,:activity,:campaign).find_each do |production|
        next unless production.active?
        variety = Nomen::Varieties[production.variant.variety]
        next unless variety <= :triticum_aestivum or variety <= :triticum_durum or variety <= :zea or variety <= :hordeum
        year = production.campaign.name.to_i
        Ekylibre::FirstRun::Booker.production = production
        production.supports.joins(:storage,:activity).find_each do |support|
          next unless support.active?
          land_parcel = support.storage
          next unless area = land_parcel.shape_area
          coeff = (area.to_s.to_f / 10000.0) / 6.0
          # Harvest 01-07-M 30-07-M
          sowing = support.interventions.where(reference_name: "sowing").where("started_at < ?", Date.civil(year, 7, 1)).order("stopped_at DESC").first
          if cultivation = sowing.casts.find_by(reference_name: 'cultivation').actor rescue nil
            Ekylibre::FirstRun::Booker.intervene(:grains_harvest, year, 7, 1, 3.13 * coeff, support: support) do |i|
              i.add_cast(reference_name: 'cropper',        actor: i.find(Product, can: "harvest(poaceae)"))
              i.add_cast(reference_name: 'cropper_driver', actor: i.find(Worker))
              i.add_cast(reference_name: 'cultivation',    actor: cultivation)
              i.add_cast(reference_name: 'grains',         population: 4.2 * coeff, variant: ProductNatureVariant.find_or_import!(:grain, derivative_of: cultivation.variety).first)
              i.add_cast(reference_name: 'straws',         population: 1.5 * coeff, variant: ProductNatureVariant.find_or_import!(:straw, derivative_of: cultivation.variety).first)
            end
          end
          w.check_point
        end
      end
    end
    GC.start

    # intervention for animal treatment
    first_run.count :animal_treatment_interventions do |w|
      workers = Worker.all
      products = Product.where(variety: 'preparation').can('care(bos)').all
      Production.joins(:variant,:campaign).find_each do |production|
        variety = Nomen::Varieties[production.variant.variety]
        next unless variety <= :bos
        year = production.campaign.name.to_i
        Ekylibre::FirstRun::Booker.production = production
        production.supports.joins(:storage).find_each do |support|
          next unless support.storage.is_a?(AnimalGroup)
          support.storage.members_at.find_each do |animal|
            Ekylibre::FirstRun::Booker.intervene(:animal_treatment, year - 1, 9, 15, 0.5, support: support, parameters: {readings: {"base-animal_treatment-0-100-1" => "false"}}) do |i|
              i.add_cast(reference_name: 'animal',           actor: animal)
              i.add_cast(reference_name: 'caregiver',        actor: workers.sample)
              i.add_cast(reference_name: 'animal_medicine',  actor: products.sample)
              i.add_cast(reference_name: 'animal_medicine_to_give', population: 1 + rand(3))
            end
          end
          w.check_point
          GC.start
        end
      end
    end

    # intervention for animal insemination
    first_run.count :animal_insemination_interventions do |w|
      workers = Worker.can('administer_inseminate(animal)').all
      products = Product.where(variety: :vial).derivative_of(:bos).can('inseminate(animal)').all
      unless workers.any?
        puts "No workers".red
        break
      end
      unless products.any?
        puts "No vials".red
        break
      end
      Production.joins(:variant,:campaign).find_each do |production|
        variety = Nomen::Varieties[production.variant.variety]
        next unless variety <= :bos and production.variant.sex == 'female'
        year = production.campaign.name.to_i
        Ekylibre::FirstRun::Booker.production = production
        production.supports.joins(:storage).find_each do |support|
          next unless support.storage.is_a?(AnimalGroup)
          support.storage.members_at.find_each do |animal|
            Ekylibre::FirstRun::Booker.intervene(:animal_artificial_insemination, year - 1, 9, 15, 0.5, support: support, parameters: {readings: {"base-animal_artificial_insemination-0-400-0" => "heat", "base-animal_artificial_insemination-0-400-1" => "true", "base-animal_artificial_insemination-0-400-2" => "false"}}) do |i|
              i.add_cast(reference_name: 'animal',       actor: animal)
              i.add_cast(reference_name: 'inseminator',  actor: workers.sample)
              i.add_cast(reference_name: 'vial',         actor: products.sample)
              i.add_cast(reference_name: 'vial_to_give', population: 1)
            end
          end
          w.check_point
          GC.start
        end
      end
    end

    first_run.count :wine_interventions do |w|
      Production.joins(:variant,:campaign).find_each do |production|
        variety = Nomen::Varieties[production.variant.variety]
        next unless variety <= :wine
        year = production.campaign.name.to_i
        Ekylibre::FirstRun::Booker.production = production
        production.supports.joins(:storage).find_each do |support|
          next unless support.storage.contents.count > 0
          Ekylibre::FirstRun::Booker.intervene(:complete_wine_transfer, year - 1, 9, 15, 0.5, support: support ) do |i|
            i.add_cast(reference_name: 'tank',             actor: support.storage)
            i.add_cast(reference_name: 'wine',             actor: support.storage.contents.first)
            i.add_cast(reference_name: 'wine_man',         actor: i.find(Worker))
            i.add_cast(reference_name: 'destination_tank', actor: i.find(Equipment, can: "store(wine)", can: "store_liquid"))
          end
        end
        w.check_point
      end
    end

    file = first_run.path("alamano", "documents", "prescription_1.jpg")
    if file.exist?
      first_run.count :animal_prescriptions do |w|

        # import veterinary prescription in PDF
        document = Document.create!(key: "2100000303_prescription_001", name: "prescription-2100000303", nature: "prescription")
        document.archive(file, :jpg)
        #File.open(file, "rb:ASCII-8BIT") do |f|
        #  document.archive(f.read, :jpg)
        #end

        # create a veterinary
        veterinary = Person.create!(
                                    :first_name => "Veto",
                                    :last_name => "PONTO",
                                    :nature => :person,
                                    :client => false,
                                    :supplier => false
                                    )

        # create veterinary prescription with PDF and veterinary
        prescription = Prescription.create!(prescriptor: veterinary, document: document, reference_number: "2100000303")

        # create an issue for all interventions on animals and update them with prescription and recommender
        Intervention.of_nature(:animal_illness_treatment).find_each do |intervention|
          # create an issue
          animal = intervention.casts.of_role('animal_illness_treatment-target').first.actor
          started_at = (intervention.started_at - 1.day) || Time.now
          nature = [:mammite, :edema, :limping, :fever, :cough, :diarrhea].sample
          issue = Issue.create!(target_type: animal.class.name, target_id: animal.id, priority: 3, observed_at: started_at, nature: nature, state: ["opened", "closed", "aborted"].sample)
          # add prescription on intervention
          intervention.issue = issue
          intervention.prescription = prescription
          intervention.recommended = true
          intervention.recommender = veterinary
          intervention.save!
          w.check_point
        end
      end

    end


    # populate crumbs
    path = first_run.path("alamano", "trips", "trip_simulation.shp")
    if path.exist?
      first_run.count :trip_simulation do |w|
        #############################################################################
        read_at = Time.new(2014, 5, 5, 10, 0, 0, "+00:00")
        user = User.where(person_id: Worker.pluck(:person_id).compact).first
        RGeo::Shapefile::Reader.open(path.to_s, :srid => 4326) do |file|
          file.each do |record|
            metadata = record.attributes['metadata'].blank? ? {} : record.attributes['metadata'].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
              h[i.first.strip.downcase.to_s] = i.second.to_s
              h
            }
            Crumb.create!(accuracy: 1,
                          geolocation: record.geometry,
                          metadata: metadata,
                          nature: record.attributes['nature'].to_sym,
                          read_at: read_at + record.attributes['id'].to_i * 15,
                          user_id: user.id,
                          device_uid: record.attributes['device_uid'] || 'demo:123854'
                          )
            # w.check_point
          end
        end
      end
    end

  end

end
