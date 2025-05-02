import LLM "mo:llm";
import Text "mo:base/Text";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Hash "mo:base/Hash";
import Error "mo:base/Error";
import Blob "mo:base/Blob";
import List "mo:base/List";
import Principal "mo:base/Principal";
import Array "mo:base/Array"; 
import Option "mo:base/Option";

actor AnonymousOpinions {
  // Type for storing media
  type MediaType = {
    #image;
    #video;
  };

  type Media = {
    mediaType: MediaType;
    content: Blob;
  };

  // Type for storing votes
  type Vote = {
    #up;
    #down;
  };

  // Type for tracking user points details
  type UserPointsTracker = {
    totalPoints: Nat;
    remainingPoints: Nat;
  };

  // Type for storing opinions with votes and replies
  type Opinion = {
    id: Nat;
    content: Text;
    timestamp: Time.Time;
    media: ?Media;
    upvotes: Nat;
    downvotes: Nat;
    parentId: ?Nat; // Optional parent ID for replies
  };

  // Type for tracking user votes
  type UserVote = {
    opinionId: Nat;
    vote: Vote;
  };

  // Constants for point system
  let POST_OPINION_POINTS: Nat = 20;  // Cost to post an opinion
  let REPLY_POINTS_EARNED: Nat = 5;   // Points earned for replying
  let REPLY_POINTS_COST: Nat = 5;     // Points cost to reply
  let MINIMUM_POINTS_TO_POST: Nat = 20;
  let DEFAULT_INITIAL_POINTS: Nat = 50;

  // Stable variables for persistence across upgrades
  stable var nextId: Nat = 0;
  stable var opinionsEntries: [(Nat, Opinion)] = [];
  stable var userVotesEntries: [(Principal, [UserVote])] = [];
  stable var userPointsEntries: [(Principal, UserPointsTracker)] = [];
  
  // LLM configuration
  let defaultPrompt = "analisa text ini, dan berikan output 1 jika termasuk hinaan dan berikan output 0 jika tidak terindikasi hinaan. hanya beri saya input 0 atau 1.";
  let MAX_INPUT_LENGTH = 280;

  // Use HashMap for more efficient lookups by ID
  let opinions = HashMap.fromIter<Nat, Opinion>(
    opinionsEntries.vals(), 
    10, 
    Nat.equal, 
    Hash.hash
  );

  // Track user votes to prevent multiple votes on the same opinion
  let userVotes = HashMap.fromIter<Principal, [UserVote]>(
    userVotesEntries.vals(),
    10,
    Principal.equal,
    Principal.hash
  );

  // Track user points with more detailed tracking
  let userPoints = HashMap.fromIter<Principal, UserPointsTracker>(
    userPointsEntries.vals(),
    10,
    Principal.equal,
    Principal.hash
  );

  // Initialize user points with default values
  private func initializeUserPoints(principal: Principal) : UserPointsTracker {
    let pointsTracker : UserPointsTracker = {
      totalPoints = DEFAULT_INITIAL_POINTS;
      remainingPoints = DEFAULT_INITIAL_POINTS;
    };
    userPoints.put(principal, pointsTracker);
    pointsTracker
  };

  // Check content using LLM
  public func checkContentWithLLM(content: Text) : async Bool {
    if (Text.size(content) > MAX_INPUT_LENGTH) {
      throw Error.reject("Error: Input exceeds 280 character limit");
    };
    
    let fullPrompt = defaultPrompt # " " # content;
    let result = await LLM.prompt(#Llama3_1_8B, fullPrompt);
    
    // Check if result contains "1" which indicates inappropriate content
    return Text.contains(result, #text "1");
  };

  // Simple filter function as backup
  private func containsInappropriateContent(text: Text) : Bool {
    let lowercaseText = Text.toLowercase(text);
    
    // Define a list of inappropriate words to filter
    let inappropriateWords = ["bajingan", "asu", "kontol"];
    
    for (word in inappropriateWords.vals()) {
      if (Text.contains(lowercaseText, #text word)) {
        return true;
      };
    };
    
    return false;
  };

  // Get detailed user points information
  public query(msg) func getUserPointsDetails() : async UserPointsTracker {
    let caller = msg.caller;
    switch (userPoints.get(caller)) {
      case null { initializeUserPoints(caller) };
      case (?pointsTracker) { pointsTracker };
    };
  };

  // Modify point tracking function to update both total and remaining points
  private func updateUserPoints(
    principal: Principal, 
    pointsEarned: Nat, 
    pointsSpent: Nat
  ) : () {
    let currentPointsTracker = switch (userPoints.get(principal)) {
      case null { initializeUserPoints(principal) };
      case (?tracker) { tracker };
    };

    let updatedPointsTracker : UserPointsTracker = {
      totalPoints = currentPointsTracker.totalPoints + pointsEarned - pointsSpent;
      remainingPoints = currentPointsTracker.remainingPoints + pointsEarned - pointsSpent;
    };

    userPoints.put(principal, updatedPointsTracker);
  };

  // Modified postOpinion function with new points system
  public shared(msg) func postOpinion(
    content: Text, 
    media: ?Media, 
    parentId: ?Nat
  ) : async Nat {
    let caller = msg.caller;
    
    // Get current user points
    let pointsTracker = switch (userPoints.get(caller)) {
      case null { initializeUserPoints(caller) };
      case (?tracker) { tracker };
    };

    // Check if user has enough remaining points
    if (pointsTracker.remainingPoints < MINIMUM_POINTS_TO_POST) {
      throw Error.reject(
        "Not enough points to post an opinion. Minimum " # 
        Nat.toText(MINIMUM_POINTS_TO_POST) # " points required. " #
        "You have " # Nat.toText(pointsTracker.remainingPoints) # " remaining points."
      );
    };

    // Validate content
    if (Text.size(content) == 0) {
      throw Error.reject("Opinion content cannot be empty");
    };
    
    // First check with simple filter
    if (containsInappropriateContent(content)) {
      throw Error.reject("Opinion contains inappropriate content");
    };
    
    // Then check with LLM for more advanced detection
    let isInappropriate = await checkContentWithLLM(content);
    if (isInappropriate) {
      throw Error.reject("Opinion contains inappropriate content detected by AI");
    };
    
    // Validate parent opinion if it's a reply
    switch (parentId) {
      case (?pid) {
        switch (opinions.get(pid)) {
          case null {
            throw Error.reject("Parent opinion does not exist");
          };
          case _ {};
        };
      };
      case null {};
    };
    
    let newOpinion: Opinion = {
      id = nextId;
      content = content;
      timestamp = Time.now();
      media = media;
      upvotes = 0;
      downvotes = 0;
      parentId = parentId;
    };
    
    opinions.put(nextId, newOpinion);
    
    // Deduct points for posting
    updateUserPoints(
      caller, 
      0,  // Points earned
      MINIMUM_POINTS_TO_POST  // Points spent
    );
    
    // Increment the next available ID
    nextId += 1;
    return newOpinion.id;
  };

  // Enhanced reply function with points tracking
  public shared(msg) func replyToOpinion(
    content: Text, 
    parentId: Nat, 
    media: ?Media
  ) : async Nat {
    let caller = msg.caller;
    
    // Get current user points
    let pointsTracker = switch (userPoints.get(caller)) {
      case null { initializeUserPoints(caller) };
      case (?tracker) { tracker };
    };

    // Check if user has enough remaining points to reply
    if (pointsTracker.remainingPoints < REPLY_POINTS_COST) {
      throw Error.reject(
        "Not enough points to reply. " # 
        Nat.toText(REPLY_POINTS_COST) # " points required. " #
        "You have " # Nat.toText(pointsTracker.remainingPoints) # " remaining points."
      );
    };

    // Validate parent opinion exists
    let parentOpinion = switch (opinions.get(parentId)) {
      case null {
        throw Error.reject("Parent opinion does not exist");
      };
      case (?opinion) { opinion };
    };

    // Validate content length
    if (Text.size(content) == 0) {
      throw Error.reject("Reply content cannot be empty");
    };

    // Determine reply depth and enforce a maximum depth limit
    let replyDepth = switch (parentOpinion.parentId) {
      case null { 1 }; // Direct reply to top-level opinion
      case (?pid) { 
        switch (opinions.get(pid)) {
          case null { 1 }; 
          case (?grandparentOpinion) { 
            // Prevent nested replies beyond 2 levels
            if (grandparentOpinion.parentId != null) {
              throw Error.reject("Maximum reply depth reached");
            };
            2 
          };
        }
      };
    };

    // Content moderation checks
    if (containsInappropriateContent(content)) {
      throw Error.reject("Reply contains inappropriate content");
    };
    
    let isInappropriate = await checkContentWithLLM(content);
    if (isInappropriate) {
      throw Error.reject("Reply contains inappropriate content detected by AI");
    };

    // Create new reply opinion
    let newReplyOpinion: Opinion = {
      id = nextId;
      content = content;
      timestamp = Time.now();
      media = media;
      upvotes = 0;
      downvotes = 0;
      parentId = ?parentId;
    };
    
    opinions.put(nextId, newReplyOpinion);
    
    // Update points: Deduct reply cost and add reply points
    updateUserPoints(
      caller, 
      REPLY_POINTS_EARNED,  // Points earned for replying
      REPLY_POINTS_COST     // Points spent to reply
    );
    
    // Increment the next available ID
    nextId += 1;
    return newReplyOpinion.id;
  };

  // Helper function to find a vote in a user's vote list
  private func findVote(votes: [UserVote], opinionId: Nat) : ?(UserVote, Nat) {
    var index = 0;
    for (vote in votes.vals()) {
      if (vote.opinionId == opinionId) {
        return ?(vote, index);
      };
      index += 1;
    };
    null
  };

  // Improved Vote on an opinion (upvote or downvote)
  public shared(msg) func voteOnOpinion(opinionId: Nat, vote: Vote) : async () {
    let caller = msg.caller;
    
    // Check if opinion exists
    switch (opinions.get(opinionId)) {
      case null {
        throw Error.reject("Opinion does not exist");
      };
      case (?opinion) {
        // Get user's existing votes
        let userVotesList = switch (userVotes.get(caller)) {
          case null { [] };
          case (?votes) { votes };
        };
        
        // Find existing vote for this opinion
        let existingVoteResult = findVote(userVotesList, opinionId);
        
        // Updated opinion with modified vote counts
        var updatedOpinion = opinion;
        
        switch (existingVoteResult) {
          case null {
            // New vote: increment appropriate counter
            updatedOpinion := switch (vote) {
              case (#up) { 
                { opinion with upvotes = opinion.upvotes + 1 } 
              };
              case (#down) { 
                { opinion with downvotes = opinion.downvotes + 1 } 
              };
            };
            
            // Add new vote to user's vote list
            let updatedVotes = Array.append(
              userVotesList, 
              [{ opinionId = opinionId; vote = vote }]
            );
            userVotes.put(caller, updatedVotes);
          };
          case (?(existingVote, index)) {
            // If vote is the same, do nothing
            if (existingVote.vote == vote) return;
            
            // Change vote: adjust counters
            updatedOpinion := switch (existingVote.vote, vote) {
              case (#up, #down) { 
                { opinion with 
                  upvotes = opinion.upvotes - 1; 
                  downvotes = opinion.downvotes + 1 
                } 
              };
              case (#down, #up) { 
                { opinion with 
                  upvotes = opinion.upvotes + 1; 
                  downvotes = opinion.downvotes - 1 
                } 
              };
              case _ { opinion }; // Impossible case, but needed for exhaustiveness
            };
            
            // Update user's vote
            let updatedVotes = Array.tabulate<UserVote>(
              userVotesList.size(), 
              func(i: Nat) : UserVote { 
                if (i == index) {
                  {
                    opinionId = opinionId;
                    vote = vote;
                  }
                } else {
                  userVotesList[i] 
                }
              }
            );
            userVotes.put(caller, updatedVotes);
          };
        };
        
        // Update the opinion in the HashMap
        opinions.put(opinionId, updatedOpinion);
      };
    };
  };

  // Query function to get all top-level opinions (not replies)
  public query func getAllOpinions() : async [Opinion] {
    Iter.toArray(
      Iter.filter(
        opinions.vals(), 
        func (opinion: Opinion): Bool { 
          switch (opinion.parentId) {
            case null { true };
            case _ { false };
          }
        }
      )
    );
  };

  // Query function to get an opinion by ID
  public query func getOpinion(id: Nat) : async ?Opinion {
    opinions.get(id);
  };
  
  // Get replies to a specific opinion
  public query func getReplies(opinionId: Nat) : async [Opinion] {
    Iter.toArray(
      Iter.filter(
        opinions.vals(),
        func (opinion: Opinion): Bool {
          switch (opinion.parentId) {
            case (?pid) { pid == opinionId };
            case null { false };
          }
        }
      )
    );
  };

  // Get a conversation thread (original opinion and its replies)
  public query func getConversationThread(opinionId: Nat) : async {
    originalOpinion: ?Opinion;
    replies: [Opinion];
  } {
    let originalOpinion = opinions.get(opinionId);
    let threadReplies = Iter.toArray(
      Iter.filter(
        opinions.vals(),
        func (opinion: Opinion): Bool {
          switch (opinion.parentId) {
            case (?pid) { pid == opinionId };
            case null { false };
          }
        }
      )
    );

    return {
      originalOpinion = originalOpinion;
      replies = threadReplies;
    };
  };

  // Optional: Get total reply count for an opinion
  public query func getReplyCount(opinionId: Nat) : async Nat {
    Iter.size(
      Iter.filter(
        opinions.vals(),
        func (opinion: Opinion): Bool {
          switch (opinion.parentId) {
            case (?pid) { pid == opinionId };
            case null { false };
          }
        }
      )
    );
  };
  
  // Get a user's vote on a specific opinion
  public query(msg) func getUserVote(opinionId: Nat) : async ?Vote {
    let caller = msg.caller;
    
    switch (userVotes.get(caller)) {
      case null { null };
      case (?votes) {
        for (vote in votes.vals()) {
          if (vote.opinionId == opinionId) {
            return ?vote.vote;
          };
        };
        null;
      };
    };
  };
  
  // System functions for data persistence
  system func preupgrade() {
    opinionsEntries := Iter.toArray(opinions.entries());
    userVotesEntries := Iter.toArray(userVotes.entries());
    userPointsEntries := Iter.toArray(userPoints.entries());
  };

  system func postupgrade() {
    opinionsEntries := [];
    userVotesEntries := [];
    userPointsEntries := [];
  };
}