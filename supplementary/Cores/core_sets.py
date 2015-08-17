from itertools import combinations, chain
from collections import OrderedDict as odict

from tempfile import mkdtemp
from joblib import Memory

from rdkit import Chem
from rdkit.Chem.MCS import FindMCS

import pandas as pd

import networkx as nx

from local_utils.rdkit_utils import pairwise_sim

import logging
# reload(logging) # Seems to be required to get logging from modules working
logging.basicConfig(level=logging.DEBUG, format="[%(asctime)s %(levelname)-8s] %(message)s", datefmt="%Y/%b/%d %H:%M:%S")

####################################################################################################

verbose = False

######

# Default weights for the descriptors...

weights = odict((
      ('mol_atom_diff',  1.0)
    , ('mcs_atom_diff',  1.0)
    , ('mcs_bond_diff',  2.0)
    , ('ring_bond_diff', 3.0)
))


######

# Atom equivalences (NB these are ordered, so precedences may (in principle) be specified)...

equivalencies = odict(( 
      ('Aliphatic_C_O_S', {
          'smarts': '[CX4H2,OH0,SX2H0]' #;!$(*C=O)]'
        , 'AtomicNum': 6
      })
    , ('Aromatic_C_O_S',  {
          'smarts': '[cH,oX2,sX2]'
        , 'AtomicNum': 6
      })
))

for x in equivalencies.values(): x['pattern'] = Chem.MolFromSmarts(x['smarts'])
    
####################################################################################################
    
# Utility to count difference in number of ring bonds between pair of molecules...

def get_ring_bond_diff(mol_0, mol_1):
    
    return abs(sum(x.IsInRing() for x in mol_0.GetBonds()) - sum(x.IsInRing() for x in mol_1.GetBonds()))

######

# Utility to set atom equivalences...

memory = Memory(cachedir=mkdtemp(), verbose=0)

@memory.cache
def set_equivalents(mol_in):

    mol = Chem.Mol(mol_in)

    atom_sets = {k: set(chain.from_iterable(mol.GetSubstructMatches(v['pattern']))) for k, v in equivalencies.items()}

    for atom in mol.GetAtoms():

        found = False

        for name, record in equivalencies.items():

            if atom.GetIdx() in atom_sets[name]: # take first match

                found = True

                atom.SetIsotope(record['AtomicNum'])

                break 

        if not found:

            atom.SetIsotope(atom.GetAtomicNum())
            
    return mol

####################################################################################################

# 1) Get difference score using atom elements...

def get_diff_1(mol_0, mol_1, atomCompare='elements'):
    
    # Get counts for pair of molecules...
    
    n_atom_0, n_atom_1 = len(mol_0.GetAtoms()), len(mol_1.GetAtoms())
      
    n_bond_0, n_bond_1 = len(mol_0.GetBonds()), len(mol_1.GetBonds())

    mol_atom_diff = abs(n_atom_1 - n_atom_0)

    if mol_atom_diff > 3: return 998 #@@@

    ring_bond_diff = get_ring_bond_diff(mol_0, mol_1)

    if ring_bond_diff > 3: return 997 #@@@

    if n_atom_1 > n_atom_0:
        
        n_bond_1 = n_bond_1 - (n_atom_1 - n_atom_0)

    else:

        n_bond_0 = n_bond_0 - (n_atom_0 - n_atom_1)
    
    n_atom_mcs = FindMCS([mol_0, mol_1], atomCompare=atomCompare, bondCompare="any",     ).numAtoms
    
    n_bond_mcs = FindMCS([mol_0, mol_1], atomCompare="any",      bondCompare="bondtypes").numBonds
    
    # Descriptors for pair...
    
    descriptors = {
          'mol_atom_diff':  mol_atom_diff
        , 'mcs_atom_diff':  min(n_atom_0, n_atom_1) - n_atom_mcs
        , 'ring_bond_diff': ring_bond_diff
        , 'mcs_bond_diff':  min(n_bond_1, n_bond_0) - n_bond_mcs
    }
            
    score = sum(descriptors[x] * weights[x] for x in weights.keys())

    return score

######

# 2) Get difference score using atom equivalences...

def get_diff_2(mol_0, mol_1):

    return get_diff_1(set_equivalents(mol_0), set_equivalents(mol_1), atomCompare='isotopes')

####################################################################################################

# Get diffs for input list of cores...

def get_core_diffs(cores):

    if verbose: logging.info("Number of cores: {}".format(len(cores)))
    
    combos = list(combinations(range(len(cores)), 2))

    n_total = len(combos)

    if verbose: logging.info("Number of combinations: {}".format(n_total))

    def f(i, j, n):

        if verbose and n % 100 == 0: logging.info("Done {}/{} ({:.1f} %)".format(n, n_total, 100.0*n/n_total))

        mol_0, mol_1 = cores[i], cores[j]

        sim = round(pairwise_sim(mol_0, mol_1), 2)

        if sim > 0.2: #@@@

            diff_1 = get_diff_1(mol_0, mol_1)

            diff_2 = get_diff_2(mol_0, mol_1)

        else:

            diff_2 = diff_1 = 999

        return pd.Series([i, j, mol_0, mol_1, sim, diff_1, diff_2], index=['i', 'j', 'mol_0', 'mol_1', 'sim', 'diff_1', 'diff_2'])

    df = pd.DataFrame(f(i, j, n) for n, (i, j) in enumerate(combos, 1))

    return df

####################################################################################################

def get_core_sets(df, threshold=0):

    graph = nx.Graph()

    edge_labels = {}

    for i, j, dist in df[['i', 'j', 'diff_2']].to_records(index=False):

        graph.add_node(i)
        graph.add_node(j)

        if dist > threshold: continue

        graph.add_edge(i, j, weight=(threshold-dist), dist=dist)

        edge_labels = {edge: graph.get_edge_data(*edge)['dist'] for edge in graph.edges()}

    node_labels = {node: node for node in graph.nodes()}

    subgraphs = list(nx.connected_components(graph))
    
    return subgraphs, [graph, node_labels, edge_labels]

####################################################################################################
# End
####################################################################################################
