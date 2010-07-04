class Quango < ActiveRecord::Base
  PossibleTypes = { 'NDPB' => ['Non-Departemental Body'],
                    'ALB' => ['Arms Length Body'],
                    'Public Corporation' => ['Public Corporation'],
                    'Association' => ['Association'],
                    'RIEP' => 'Regional Improvement & Efficiency Partnership'}
                    
end
