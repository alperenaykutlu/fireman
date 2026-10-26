namespace Fireman.Domain.Characters;

/// <summary>Player-selected appearance, stored independently from gameplay equipment.</summary>
public class CharacterCustomization
{
    public Guid ProfileId { get; private set; }
    public string Gender { get; private set; } = "male";
    public string Hat { get; private set; } = "Standart kask";
    public int HatStyle { get; private set; }
    public string Suit { get; private set; } = "Klasik itfaiye ceketi";
    public int SuitStyle { get; private set; }
    public string Accessory { get; private set; } = "Hortum seti";
    public long SkinColorValue { get; private set; } = 4294955428L;
    public long SuitColorValue { get; private set; } = 4292617766L;
    public string Mask { get; private set; } = "Standart maske";
    public string Gloves { get; private set; } = "Standart eldiven";
    public string Shoes { get; private set; } = "Standart ayakkabı";
    public string Bomb { get; private set; } = "Klasik dinamit";
    public DateTime UpdatedAt { get; private set; }

    private CharacterCustomization() { }

    public CharacterCustomization(Guid profileId, string gender, string hat, int hatStyle, string suit, int suitStyle, string accessory, long skinColorValue = 4294955428L, long suitColorValue = 4292617766L, string mask = "Standart maske", string gloves = "Standart eldiven", string shoes = "Standart ayakkabı", string bomb = "Klasik dinamit")
    {
        ProfileId = profileId;
        Update(gender, hat, hatStyle, suit, suitStyle, accessory, skinColorValue, suitColorValue, mask, gloves, shoes, bomb);
    }

    public void Update(string gender, string hat, int hatStyle, string suit, int suitStyle, string accessory, long skinColorValue = 4294955428L, long suitColorValue = 4292617766L, string mask = "Standart maske", string gloves = "Standart eldiven", string shoes = "Standart ayakkabı", string bomb = "Klasik dinamit")
    {
        if (gender is not ("male" or "female")) throw new ArgumentException("Gender must be male or female.");
        if (hatStyle is < 0 or > 49 || suitStyle is < 0 or > 49) throw new ArgumentOutOfRangeException(nameof(hatStyle));
        Gender = gender;
        Hat = string.IsNullOrWhiteSpace(hat) ? "Standart kask" : hat.Trim();
        HatStyle = hatStyle;
        Suit = string.IsNullOrWhiteSpace(suit) ? "Klasik itfaiye ceketi" : suit.Trim();
        SuitStyle = suitStyle;
        Accessory = string.IsNullOrWhiteSpace(accessory) ? "Hortum seti" : accessory.Trim();
        SkinColorValue = skinColorValue;
        SuitColorValue = suitColorValue;
        Mask = string.IsNullOrWhiteSpace(mask) ? "Standart maske" : mask.Trim();
        Gloves = string.IsNullOrWhiteSpace(gloves) ? "Standart eldiven" : gloves.Trim();
        Shoes = string.IsNullOrWhiteSpace(shoes) ? "Standart ayakkabı" : shoes.Trim();
        Bomb = string.IsNullOrWhiteSpace(bomb) ? "Klasik dinamit" : bomb.Trim();
        UpdatedAt = DateTime.UtcNow;
    }
}
