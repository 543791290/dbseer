% Copyright 2013 Barzan Mozafari
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%     http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

function T = probOfBeingChosenAtLeastOnce(PP, freq, tps)
% PP(i,g) is the probability of type i touching page 'g' 
%       note that sum(i,:) does not need to be one at all!
% tps(i) is the number of transactions of type i.
%
% T(g) is the probability that at least one of the tps transactions touch g

effectiveTPS = freq;

for i=1:size(effectiveTPS,1)
    effectiveTPS(i,:) = effectiveTPS(i,:) * tps(i);
end

%PP(1,:) = PP(1,:) / 50;
PP = PP / 70;
PP(PP>1)=1;

%P(i,p)= the probability of page 'p' staying CLEAN from a tran type 'i'
%after effectiveTPS recurrence of tran type 'i'
P = (1-PP).^effectiveTPS;

%first let's calculate the probability that none of the tps transactions
%touch a page
T = prod(P,1);

%now 1-T is the probability that at least one of the transactions touch them!
T = 1-T;
end
