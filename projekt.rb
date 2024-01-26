class ElektricniProizvod

    def initialize(naziv, brend, cijena)
      @naziv = naziv
      @brend = brend
      @cijena = cijena
    end

    #getteri
    def get_naziv
        @naziv
    end

    def get_brend
        @brend
    end

    def get_cijena
        @cijena
    end

    #setteri
    def set_naziv(noviNaziv)
        @naziv = noviNaziv
    end

    def set_brend(noviBrend)
        @brend = noviBrend
    end

    def set_cijena(novaCijena)
        @cijena = novaCijena
    end
  
    def opis
      ""
    end

    def to_hash
        {
        'json_class' => self.class.name,
        'naziv' => @naziv,
        'brend' => @brend,
        'cijena' => @cijena
        }
    end
end

class Smartphone < ElektricniProizvod
    
    def initialize (naziv, brend, cijena, kolicinaMemorije)
        super naziv, brend, cijena
        @kolicinaMemorije = kolicinaMemorije
    end

    #getter
    def get_kolicinaMemorije
        @kolicinaMemorije
    end

    #setter
    def set_kolicinaMemorije(novaKolicinaMemorije)
      @kolicinaMemorije = novaKolicinaMemorije
    end

    def opis
      super + "Smartphone"
    end

    def to_hash
        super.merge('kolicinaMemorije' => @kolicinaMemorije)
    end
end

class TV < ElektricniProizvod
    
    def initialize (naziv, brend, cijena, velicinaEkrana)
        super naziv, brend, cijena
        @velicinaEkrana = velicinaEkrana
    end

    #getter
    def get_velicinaEkrana
        @velicinaEkrana
    end

    #setter
    def set_velicinaEkrana(novaVelicinaEkrana)
        @velicinaEkrana = novaVelicinaEkrana
    end

    def opis
      super + "TV"
    end

    def to_hash
        super.merge('velicinaEkrana' => @velicinaEkrana)
    end
end


module ElektricniProizvodManager
    require 'json'

  def ucitaj_podatke
    file_path = File.join(File.dirname(__FILE__), 'elektricni_proizvodi.json')
    if File.exist?(file_path)
      podaci = File.read(file_path)
      elektricni_proizvodi = JSON.parse(podaci).map do |podatak|
        class_name = podatak['json_class']
        case class_name
          when 'Smartphone'
            Smartphone.new(podatak['naziv'], podatak['brend'], podatak['cijena'], podatak['kolicinaMemorije'])
          when 'TV'
            TV.new(podatak['naziv'], podatak['brend'], podatak['cijena'], podatak['velicinaEkrana'])
        end
      end
    else
      elektricni_proizvodi = []
    end
    elektricni_proizvodi
  end


  def spremi_podatke(elektricni_proizvodi)
    file_path = File.join(File.dirname(__FILE__), 'elektricni_proizvodi.json')
    serialized_data = JSON.generate(elektricni_proizvodi.map(&:to_hash))
    File.write(file_path, serialized_data)
  end

  def dodaj_smartphone(elektricni_proizvodi, naziv, brend, cijena, kolicinaMemorije)
    cijena = cijena.to_f
    kolicinaMemorije = kolicinaMemorije.to_i
    if !naziv.empty? && !brend.empty? && cijena != 0.0 && kolicinaMemorije != 0
      elektricni_proizvodi << Smartphone.new(naziv, brend, cijena, kolicinaMemorije)
    end
  end

  def dodaj_tv(elektricni_proizvodi, naziv, brend, cijena, velicinaEkrana)
    cijena = cijena.to_f
    velicinaEkrana = velicinaEkrana.to_f
    if !naziv.empty? && !brend.empty? && cijena != 0.0 && velicinaEkrana != 0.0
      elektricni_proizvodi << TV.new(naziv, brend, cijena, velicinaEkrana)
    end
  end

  def pobrisi(naziv, elektricni_proizvodi)
    elektricni_proizvodi.each { |proizvod| elektricni_proizvodi.delete(proizvod) if proizvod.get_naziv().downcase == naziv.downcase }        
  end
end


require 'fox16'
include Fox

class ElektricniProizvodApp < FXMainWindow
  include ElektricniProizvodManager

  def initialize(app)
    super(app, "Evidencija Električnih Proizvoda", width: 400, height: 400)

    elektricni_proizvodi = self.ucitaj_podatke()

    ##COMBOBOX S IZBORNIKOM
    combo = FXComboBox.new(self, 5, opts: COMBOBOX_STATIC | FRAME_SUNKEN | FRAME_THICK | LAYOUT_SIDE_TOP | LAYOUT_FILL_X)
    combo.appendItem("Unos smartphone-a")
    combo.appendItem("Unos TV-a")
    combo.appendItem("Ispis i ažuriranje proizvoda")
    combo.appendItem("Brisanje proizvoda")
    combo.appendItem("Izlaz i snimanje")
    combo.numVisible = 5

    ##PROZOR ZA UNOS PODATAKA
    @unos_frame = FXHorizontalFrame.new(self, opts: LAYOUT_FILL_X | LAYOUT_FILL_Y)
    ##VERTIKALNI PROZOR S LABELIMA UNUTAR PROZORA ZA UNOS PODATAKA
    @labela_frame = FXVerticalFrame.new(@unos_frame, opts: LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_SIDE_LEFT)
    FXLabel.new(@labela_frame, "Naziv proizvoda:")
    FXLabel.new(@labela_frame, "Brend:")
    FXLabel.new(@labela_frame, "Cijena (u €):")
    @dodatni_parametar_label = FXLabel.new(@labela_frame, "Memorija (u GB):")
    ##VERTIKALNI PROZOR S POLJIMA ZA PODATKE UNUTAR PROZORA ZA UNOS PODATAKA
    @podaci_frame = FXVerticalFrame.new(@unos_frame, opts: LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_SIDE_RIGHT)
    @naziv = FXTextField.new(@podaci_frame, 20, opts: LAYOUT_FILL_X)
    @brend = FXTextField.new(@podaci_frame, 20, opts: LAYOUT_FILL_X)
    @cijena = FXTextField.new(@podaci_frame, 20, opts: LAYOUT_FILL_X)
    @dodatni_parametar = FXTextField.new(@podaci_frame, 20, opts: LAYOUT_FILL_X)
    @tipka = FXButton.new(@podaci_frame, "Dodaj proizvod")
    ##TIPKA DODAJE PROIZVODE U LISTU OVISNO O TOME ŠTO JE ODABRANO U COMBOBOXU I RESETIRA POLJA NA PRAZNO
    @tipka.connect(SEL_COMMAND) do
      if combo.currentItem == 0
        self.dodaj_smartphone(elektricni_proizvodi, @naziv.text, @brend.text, @cijena.text, @dodatni_parametar.text)
      elsif combo.currentItem == 1
        self.dodaj_tv(elektricni_proizvodi, @naziv.text, @brend.text, @cijena.text, @dodatni_parametar.text)
      end
      @naziv.text = ""
      @brend.text = ""
      @cijena.text = ""
      @dodatni_parametar.text = ""
    end

    ##PROZOR ZA ISPIS PODATAKA
    @ispis_frame = FXHorizontalFrame.new(self, opts: LAYOUT_FILL_X | LAYOUT_FILL_Y)
    ##VERTIKALNI PROZOR S LISTOM PROIZVODA UNUTAR PROZORA ZA ISPIS
    @list_frame = FXVerticalFrame.new(@ispis_frame, opts: LAYOUT_FILL_X | LAYOUT_FILL_Y)
    @proizvodi_list = FXList.new(@list_frame, opts: LAYOUT_FILL_X | LAYOUT_FILL_Y)
    ##ISPIS DETALJA O PROIZVODU KLIKOM NA NJEGA
    @proizvodi_list.connect(SEL_COMMAND) do
      @sel_object = elektricni_proizvodi.find do |proizvod|
        proizvod.get_naziv() == @proizvodi_list.getItemText(@proizvodi_list.currentItem)
      end
      @detalji_naziv_label.setText("Naziv:")
      @detalji_naziv.text = @sel_object.get_naziv()

      @detalji_brend_label.setText("Brend:")
      @detalji_brend.text = @sel_object.get_brend()

      @detalji_cijena_label.setText("Cijena:")
      @detalji_cijena.text = @sel_object.get_cijena().to_s + "€"

      if @sel_object.respond_to?(:get_kolicinaMemorije)
        @detalji_dodatni_parametar_label.setText("Memorija:")
        @detalji_dodatni_parametar.text = @sel_object.get_kolicinaMemorije().to_s + "GB"
      elsif @sel_object.respond_to?(:get_velicinaEkrana)
        @detalji_dodatni_parametar_label.setText("Veličina ekrana:")
        @detalji_dodatni_parametar.text = @sel_object.get_velicinaEkrana().to_s + "cm"
      end
      @detalji_opis_label.setText("Tip proizvoda:")
      @detalji_opis.text = @sel_object.opis()
    end

    ##VERTIKALNI PROZOR S LABELIMA UNUTAR PROZORA ZA ISPIS
    @detalji_frame_labels = FXVerticalFrame.new(@ispis_frame, opts: LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_SIDE_RIGHT)
    @detalji_naziv_label = FXLabel.new(@detalji_frame_labels, "")
    @detalji_brend_label = FXLabel.new(@detalji_frame_labels, "")
    @detalji_cijena_label = FXLabel.new(@detalji_frame_labels, "")
    @detalji_dodatni_parametar_label = FXLabel.new(@detalji_frame_labels, "")
    @detalji_opis_label = FXLabel.new(@detalji_frame_labels, "")

    ##VERTIKALNI PROZOR S DETALJIMA PROIZVODA UNUTAR PROZORA ZA ISPIS
    @detalji_frame = FXVerticalFrame.new(@ispis_frame, opts: LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_SIDE_RIGHT)
    @detalji_naziv = FXTextField.new(@detalji_frame, 20, opts: LAYOUT_FILL_X)
    @detalji_brend = FXTextField.new(@detalji_frame, 20, opts: LAYOUT_FILL_X)
    @detalji_cijena = FXTextField.new(@detalji_frame, 20, opts: LAYOUT_FILL_X)
    @detalji_dodatni_parametar = FXTextField.new(@detalji_frame, 20, opts: LAYOUT_FILL_X)
    @detalji_opis = FXTextField.new(@detalji_frame, 20, opts: LAYOUT_FILL_X)
    @tipka_azuriraj = FXButton.new(@detalji_frame, 'Ažuriraj podatak')
    @tipka_azuriraj.connect(SEL_COMMAND) do
      if @sel_object
        @sel_object.set_naziv(@detalji_naziv.text)
        @sel_object.set_brend(@detalji_brend.text)
        @sel_object.set_cijena(@detalji_cijena.text.to_f)
        if @sel_object.respond_to?(:get_kolicinaMemorije)
          @sel_object.set_kolicinaMemorije(@detalji_dodatni_parametar.text.to_i)
        elsif @sel_object.respond_to?(:get_velicinaEkrana)
          @sel_object.set_velicinaEkrana(@detalji_dodatni_parametar.text.to_f)
        end
        @proizvodi_list.setItemText(@proizvodi_list.currentItem, @sel_object.get_naziv)
      end
    end

    ##PROZOR ZA BRISANJE PROIZVODA
    @brisanje_frame = FXVerticalFrame.new(self, opts: LAYOUT_FILL_X | LAYOUT_FILL_Y)
    FXLabel.new(@brisanje_frame, "Naziv proizvoda za brisanje:")
    @proizvod_brisanje = FXTextField.new(@brisanje_frame, 20, opts: LAYOUT_FILL_X)
    @tipka_brisanje = FXButton.new(@brisanje_frame, "Obriši proizvod")
    @tipka_brisanje.connect(SEL_COMMAND) do
      self.pobrisi(@proizvod_brisanje.text, elektricni_proizvodi)
      @proizvod_brisanje.text = ""
    end

    ##OVISNO ŠTO JE KLIKNUTO U COMBOBOXU, TAJ PROZOR SE PRIKAZUJE
    combo.connect(SEL_COMMAND) do
      case combo.currentItem
        when 0
          @unos_frame.show
          @ispis_frame.hide
          @brisanje_frame.hide
          @dodatni_parametar_label.text = "Memorija (u GB):"
        when 1
          @unos_frame.show
          @ispis_frame.hide
          @brisanje_frame.hide
          @dodatni_parametar_label.text = "Veličina ekrana (u cm):"
        when 2
          @proizvodi_list.clearItems
          elektricni_proizvodi.each do |proizvod|
          @proizvodi_list.appendItem(proizvod.get_naziv()) 
          end
          @unos_frame.hide
          @ispis_frame.show
          @brisanje_frame.hide
        when 3
          @unos_frame.hide
          @ispis_frame.hide
          @brisanje_frame.show
        when 4
          self.spremi_podatke(elektricni_proizvodi)
          getApp().stop
      end
      self.recalc
    end
  end

  def create
    super
    show(PLACEMENT_SCREEN)
  end
end

FXApp.new do |app|
  ElektricniProizvodApp.new(app)
  app.create
  app.run
end