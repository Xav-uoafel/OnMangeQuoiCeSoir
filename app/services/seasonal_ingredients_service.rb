class SeasonalIngredientsService
  SEASONAL_INGREDIENTS = {
    1 => { # Janvier
      vegetables: [
        "carotte", "poireau", "pomme de terre", "navet", "chou",
        "céleri", "panais", "topinambour", "endive", "mâche",
        "betterave", "courge", "potiron", "rutabaga"
      ],
      fruits: [
        "pomme", "poire", "orange", "clémentine", "mandarine",
        "kiwi", "citron", "pamplemousse"
      ]
    },
    2 => { # Février
      vegetables: [
        "carotte", "poireau", "pomme de terre", "navet", "chou",
        "céleri", "panais", "topinambour", "endive", "mâche",
        "betterave", "courge", "potiron", "rutabaga", "épinard"
      ],
      fruits: [
        "pomme", "poire", "orange", "clémentine", "mandarine",
        "kiwi", "citron", "pamplemousse"
      ]
    },
    3 => { # Mars
      vegetables: [
        "carotte", "poireau", "pomme de terre", "navet", "chou",
        "épinard", "endive", "radis", "asperge", "artichaut",
        "blette", "cresson", "fève"
      ],
      fruits: [
        "pomme", "poire", "citron", "pamplemousse", "rhubarbe"
      ]
    },
    4 => { # Avril
      vegetables: [
        "asperge", "radis", "épinard", "artichaut", "blette",
        "carotte nouvelle", "navet nouveau", "petit pois",
        "fève", "cresson", "laitue"
      ],
      fruits: [
        "pomme", "rhubarbe", "citron", "fraise"
      ]
    },
    5 => { # Mai
      vegetables: [
        "asperge", "radis", "petit pois", "artichaut", "blette",
        "carotte nouvelle", "navet nouveau", "courgette", "fève",
        "laitue", "oignon nouveau", "ail nouveau"
      ],
      fruits: [
        "fraise", "cerise", "rhubarbe", "groseille"
      ]
    },
    6 => { # Juin
      vegetables: [
        "artichaut", "aubergine", "courgette", "concombre",
        "haricot vert", "petit pois", "poivron", "tomate",
        "laitue", "radis", "carotte", "oignon"
      ],
      fruits: [
        "abricot", "cerise", "fraise", "framboise", "groseille",
        "melon", "pêche", "nectarine", "prune"
      ]
    },
    7 => { # Juillet
      vegetables: [
        "artichaut", "aubergine", "courgette", "concombre",
        "haricot vert", "poivron", "tomate", "laitue", "radis",
        "carotte", "oignon", "ail", "échalote"
      ],
      fruits: [
        "abricot", "cassis", "cerise", "figue", "fraise",
        "framboise", "groseille", "melon", "myrtille", "pêche",
        "nectarine", "prune", "pastèque"
      ]
    },
    8 => { # Août
      vegetables: [
        "artichaut", "aubergine", "courgette", "concombre",
        "haricot vert", "poivron", "tomate", "laitue", "radis",
        "carotte", "oignon", "ail", "échalote", "maïs"
      ],
      fruits: [
        "abricot", "figue", "framboise", "melon", "mirabelle",
        "mûre", "myrtille", "pêche", "nectarine", "poire",
        "prune", "raisin", "pastèque"
      ]
    },
    9 => { # Septembre
      vegetables: [
        "aubergine", "brocoli", "carotte", "chou", "courgette",
        "épinard", "haricot vert", "poireau", "poivron",
        "pomme de terre", "potiron", "tomate"
      ],
      fruits: [
        "figue", "framboise", "melon", "mirabelle", "mûre",
        "myrtille", "poire", "pomme", "prune", "raisin"
      ]
    },
    10 => { # Octobre
      vegetables: [
        "betterave", "brocoli", "carotte", "céleri", "chou",
        "courge", "courgette", "épinard", "navet", "poireau",
        "potiron", "topinambour"
      ],
      fruits: [
        "châtaigne", "coing", "figue", "noix", "poire",
        "pomme", "raisin"
      ]
    },
    11 => { # Novembre
      vegetables: [
        "betterave", "brocoli", "carotte", "céleri", "chou",
        "courge", "endive", "navet", "poireau", "potiron",
        "topinambour", "mâche"
      ],
      fruits: [
        "châtaigne", "coing", "kaki", "mandarine", "poire",
        "pomme"
      ]
    },
    12 => { # Décembre
      vegetables: [
        "betterave", "carotte", "céleri", "chou", "courge",
        "endive", "navet", "poireau", "potiron", "topinambour",
        "mâche"
      ],
      fruits: [
        "châtaigne", "clémentine", "mandarine", "orange",
        "pamplemousse", "poire", "pomme", "kiwi"
      ]
    }
  }

  def self.for_month(month)
    SEASONAL_INGREDIENTS[month] || { vegetables: [], fruits: [] }
  end

  def self.current
    for_month(Time.current.month)
  end
end 