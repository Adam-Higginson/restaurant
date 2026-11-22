extends GameTestSuite
## Tests for the knife's cuts as tuned in data/combat/: the cleave, the end
## of the chain, hits hardest of the three, and only a full charge flips.

const CHOP: KnifeCut = preload("res://data/combat/chop.tres")
const SLICE: KnifeCut = preload("res://data/combat/slice.tres")
const CLEAVE: KnifeCut = preload("res://data/combat/cleave.tres")
const FILLET: KnifeCut = preload("res://data/combat/fillet.tres")
const WEAK_SPIN: KnifeCut = preload("res://data/combat/weak_spin.tres")


func test_the_cleave_does_the_most_damage_of_the_chain() -> void:
	assert_int(CLEAVE.damage).is_greater(CHOP.damage)
	assert_int(CLEAVE.damage).is_greater(SLICE.damage)


func test_the_cleave_freezes_longest_of_the_chain() -> void:
	assert_int(CLEAVE.hitstop_ticks).is_greater(CHOP.hitstop_ticks)
	assert_int(CLEAVE.hitstop_ticks).is_greater(SLICE.hitstop_ticks)


func test_the_cuts_land_while_they_swing() -> void:
	for cut: KnifeCut in [CHOP, SLICE, CLEAVE, FILLET, WEAK_SPIN]:
		assert_float(cut.hit_at).is_greater(0.0)
		assert_float(cut.hit_at).is_less(cut.seconds)


func test_the_spins_hit_all_round() -> void:
	assert_float(FILLET.arc_degrees).is_equal(360.0)
	assert_float(WEAK_SPIN.arc_degrees).is_equal(360.0)


func test_the_fillet_outreaches_a_crab_lunge_and_the_weak_spin_doesnt() -> void:
	var crab_reach: float = 2.0
	assert_float(FILLET.reach).is_greater(crab_reach)
	assert_float(WEAK_SPIN.reach).is_less(crab_reach)


func test_only_the_fillet_flips_a_lunging_crab() -> void:
	assert_bool(FILLET.flips_lunging).is_true()
	for cut: KnifeCut in [CHOP, SLICE, CLEAVE, WEAK_SPIN]:
		assert_bool(cut.flips_lunging).is_false()


func test_the_fillet_hits_harder_than_the_weak_spin() -> void:
	assert_int(FILLET.damage).is_greater(WEAK_SPIN.damage)
	assert_float(FILLET.push).is_greater(WEAK_SPIN.push)
