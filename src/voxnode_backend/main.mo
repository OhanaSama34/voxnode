import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import TrieMap "mo:base/TrieMap";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Bool "mo:base/Bool";

actor {
  type Int = Int.Int;
  type Bool = Bool.Bool;

  // Konstanta reputasi
  let questionAmount: Nat = 7;
  let responseAmount: Nat = 5;
  let upvoteResponderAmount: Nat = 2;
  let upvoteQuestionerAmount: Nat = 1;
  let maxQuestionLength: Nat = 250;
  let maxAnswerLength: Nat = 250;

  // Struktur data untuk pertanyaan
  type Question = {
    text: Text;
    asker: Principal;
    answer: ?Text;
    responder: ?Principal;
  };

  var questions: [var Question] = [var];
  var balances: TrieMap.TrieMap<Principal, Int> =
    TrieMap.TrieMap(Principal.equal, Principal.hash);
  // Key = "<callerText>-<idx>"
  var hasUpvoted: TrieMap.TrieMap<Text, Bool> =
    TrieMap.TrieMap(Text.equal, Text.hash);

  // Update saldo (tidak boleh negatif)
  func updateBalance(principal: Principal, amount: Int) {
    let current = switch (balances.get(principal)) {
      case null 0;
      case (?v) v;
    };
    let newBal = current + amount;
    balances.put(principal, if (newBal < 0) 0 else newBal);
  };

  // Mengirim pertanyaan
  public shared (msg) func ask(questionText: Text): async Bool {
    assert Text.size(questionText) <= maxQuestionLength;
    let q: Question = {
      text = questionText;
      asker = msg.caller;
      answer = null;
      responder = null;
    };
    let tmp = Array.init<Question>(questions.size() + 1, q);
    for (i in questions.keys()) { tmp[i] := questions[i]; };
    questions := tmp;

    updateBalance(msg.caller, questionAmount);
    true;
  };

  // Menjawab pertanyaan
  public shared (msg) func answer(idx: Nat, answerText: Text): async Bool {
    assert idx < questions.size();
    assert Text.size(answerText) <= maxAnswerLength;

    let q = questions[idx];
    assert q.answer == null; // belum dijawab

    questions[idx] := {
      text     = q.text;
      asker    = q.asker;
      answer   = ?answerText;
      responder= ?msg.caller;
    };

    updateBalance(msg.caller, responseAmount);
    true;
  };

  // Upvote (sekali per user per question)
  public shared (msg) func upvote(idx: Nat): async Bool {
    assert idx < questions.size();
    let q = questions[idx];
    // harus sudah ada jawaban dan ada responder
    assert q.answer != null;
    assert q.responder != null;

    // tidak boleh self-upvote
    assert msg.caller != q.asker;
    // unwrap responder
    let responder = switch (q.responder) {
      case (?p) p;

    };

    // build key untuk hasUpvoted
    let callerText = Principal.toText(msg.caller);
    let key = callerText # "-" # Nat.toText(idx);

    // cek belum pernah upvote
    assert hasUpvoted.get(key) == null;

    hasUpvoted.put(key, true);

    updateBalance(q.asker, upvoteQuestionerAmount);
    updateBalance(responder, upvoteResponderAmount);
    true;
  };

  // Cek reputasi
  public query func balanceOf(who: Principal): async Int {
    switch (balances.get(who)) {
      case null    0;
      case (?v)    v;
    }
  };

  // Ambil semua pertanyaan (hanya text)
  public query func queryAllQuestions(): async [Text] {
    Array.tabulate<Text>(questions.size(), func(i: Nat): Text {
      questions[i].text;
    });
  };

  // Ambil detail satu pertanyaan (dengan jawaban & responder)
  public query func queryQuestion(idx: Nat): async ?Question {
    if (idx < questions.size()) {
      ?questions[idx]
    } else {
      null
    }
  };
};