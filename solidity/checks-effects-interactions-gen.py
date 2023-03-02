TEMPLATE = '''rules:
 -
    id: checks-effects-interactions
    message: The Checks-Effects-Interactions pattern ensures that validation of the request, and changes to the state variables of the contract, are performed before any interactions take place with other contracts. When contracts are implemented this way, the scope for Re-entrancy Attacks is reduced significantly.
    metadata:
      category: logic
      references:
        - https://entethalliance.org/specs/ethtrust-sl/v1/#req-1-use-c-e-i
    patterns:
      - pattern-inside:
          contract $C {
            $TYPE $STORAGE;
            ...
          }
      - pattern-either:
        %s
    languages: 
      - solidity
    severity: ERROR
'''

PART = '''- pattern: |
            function $F(...) {
              ...
              $ADDR.$FUNC(...);
              ...
              %s
              ...
            }
        '''

PLACEHOLDER = ''

operators = '-+/*%^|&'
for op in operators:
  for recursion in xrange(3):
    PLACEHOLDER += PART % ('$STORAGE%s %s= ...;' % ('[...]' * recursion, op))

for op in '+-':
  for recursion in xrange(3):
    PLACEHOLDER += PART % ('<... $STORAGE%s%s ...>;' % ('[...]' * recursion, op * 2))
    PLACEHOLDER += PART % ('<... %s$STORAGE%s ...>;' % (op * 2, '[...]' * recursion))

print TEMPLATE % PLACEHOLDER

TEMPLATE2 = ''' -
    id: checks-effects-interactions-heuristic
    message: The Checks-Effects-Interactions pattern ensures that validation of the request, and changes to the state variables of the contract, are performed before any interactions take place with other contracts. When contracts are implemented this way, the scope for Re-entrancy Attacks is reduced significantly.
    metadata:
      category: logic
      references:
        - https://entethalliance.org/specs/ethtrust-sl/v1/#req-1-use-c-e-i
    patterns:
      - pattern-inside:
          contract $C {
            ...
          }
      - pattern:
            function $F(...) {
              ...
              $ADDR.$FUNC(...);
              ...
              <... $WRITE(...) ...>;
              ...
            }
      - metavariable-regex:
          metavariable: $WRITE
          regex: (write|change|increase|decrease|delete|remove|add)
    languages: 
      - solidity
    severity: ERROR
'''

#PLACEHOLDER = ''
#for recursion in xrange(3):
#  PLACEHOLDER += PART % ('<... $WRITE($STORAGE%s) ...>;' % ('[...]' * recursion))

print TEMPLATE2
