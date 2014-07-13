local opponents = {

	KogaHypno = {
		type1 = "psychic",
		type2 = "psychic",
		def = 58,
		id = 129,
		spec = 88,
		hp = 107,
		speed = 56,
		level = 34,
		att = 60,
		moves = {
			{
				accuracy = 100,
				name = "Confusion",
				power = 50,
				id = 93,
				special = true,
				max_pp = 25,
				move_type = "psychic",
			}
		}
	},

	KogaWeezing = {
		type1 = "poison",
		type2 = "poison",
		def = 115,
		id = 143,
		spec = 84,
		hp = 115,
		speed = 63,
		level = 43,
		att = 90,
		moves = {
			{
				accuracy = 100,
				name = "Self-Destruct",
				power = 260,
				id = 120,
				special = false,
				max_pp = 5,
				move_type = "normal",
			}
		}
	},

	GiovanniRhyhorn = {
		type1 = "ground",
		type2 = "rock",
		def = 97,
		id = 18,
		spec = 39,
		hp = 134,
		speed = 34,
		level = 45,
		att = 89,
		moves = {
			{
				move_type = "normal",
				accuracy = 100,
				name = "Stomp",
				power = 65,
				id = 23,
				special = false,
				max_pp = 20,
				damage = 21,
			}
		}
	},

	LoreleiDewgong = {
		type1 = "water",
		type2 = "ice",
		def = 100,
		id = 120,
		spec = 116,
		hp = 169,
		speed = 89,
		level = 54,
		att = 90,
		moves = {
			{
				accuracy = 100,
				name = "Aurora-Beam",
				power = 65,
				id = 62,
				special = true,
				max_pp = 20,
				move_type = "ice",
			}
		},
		boost = {
			stat = "spec",
			mp = 2 / 3
		}
	},

	LanceGyarados = {
		type1 = "water",
		type2 = "flying",
		def = 105,
		id = 22,
		spec = 130,
		hp = 187,
		speed = 108,
		level = 58,
		att = 160,
		moves = {
			{
				accuracy = 80,
				name = "Hydro-Pump",
				power = 120,
				id = 56,
				special = true,
				max_pp = 5,
				move_type = "water",
			}
		},
		boost = {
			stat = "spec",
			mp = 1.5
		}
	},

	BluePidgeot = {
		type1 = "normal",
		type2 = "flying",
		def = 106,
		id = 151,
		spec = 100,
		hp = 182,
		speed = 125,
		level = 61,
		att = 113,
		moves = {
			{
				accuracy = 100,
				name = "Wing-Attack",
				power = 35,
				id = 17,
				special = false,
				max_pp = 35,
				move_type = "flying",
			}
		}
	},

	BlueSky = {
		type1 = "normal",
		type2 = "flying",
		def = 106,
		id = 151,
		spec = 100,
		hp = 182,
		speed = 125,
		level = 61,
		att = 113,
		moves = {
			{
				accuracy = 90,
				name = "Sky-Attack",
				power = 140,
				id = 143,
				special = false,
				max_pp = 5,
				move_type = "flying",
			}
		}
	},

}

return opponents