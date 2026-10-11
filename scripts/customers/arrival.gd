class_name Arrival
extends Resource
## One scheduled customer each day, such as lunch: due at 12:30, and still
## coming if the restaurant opens late, up until 14:00. One .tres file per
## arrival under res://data/arrivals/.
##
## Times are minutes since midnight, like [GameClock]'s (12:30 is 750).

## When the customer is due.
@export var due_minutes: int = 12 * 60 + 30
## After this, a customer who hasn't come yet doesn't come today.
@export var until_minutes: int = 14 * 60
