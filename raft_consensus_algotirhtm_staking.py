# Add staking feature. However controle plane nodes needs to be on Proof of work. This can be used so other machines from other blockchains may join as worker nodes (less secured)

class Node:
  def __init__(self, id, stake):
    self.id = id
    self.stake = stake
    self.currentTerm = 0
    self.votedFor = None
    self.log = []
    self.commitIndex = 0
    self.lastApplied = 0
    self.state = 'follower'

  def request_vote(self, term, candidate_id, last_log_index, last_log_term, candidate_stake):
    if term < self.currentTerm:
      return False
    if term > self.currentTerm or self.votedFor is None or self.votedFor == candidate_id:
      if self.log[-1].term <= last_log_term and len(self.log) <= last_log_index:
        if candidate_stake > self.stake:
          self.currentTerm = term
          self.votedFor = candidate_id
          return True
    return False

  def append_entries(self, term, leader_id, prev_log_index, prev_log_term, entries, leader_commit):
    if term < self.currentTerm:
      return False
    if len(self.log) <= prev_log_index or self.log[prev_log_index].term != prev_log_term:
      return False
    self.log = self.log[:prev_log_index+1] + entries
    if leader_commit > self.commitIndex:
      self.commitIndex = min(leader_commit, len(self.log)-1)
    return True

  def start_election(self):
    self.currentTerm += 1
    self.votedFor = self.id
    # send request_vote RPCs to all other nodes with higher stake
    # if receive votes from majority of nodes, become leader

  def send_heartbeats(self):
    # send append_entries RPCs to all other nodes

  def run(self):
    while True:
      if self.state == 'follower':
        # wait for a timeout or message from leader/candidate
        # if timeout, start election
      elif self.state == 'candidate':
        # start election
        # if receive votes from majority of nodes, become leader
        # if receive append_entries message, become follower
      elif self.state == 'leader':
        # send heartbeats to all nodes
        # if receive append_entries message, become follower
