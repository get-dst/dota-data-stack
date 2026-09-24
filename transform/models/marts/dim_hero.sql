select hero_id, hero_name, hero_key, primary_attribute, attack_type, roles
from {{ ref('stg_heroes') }}
