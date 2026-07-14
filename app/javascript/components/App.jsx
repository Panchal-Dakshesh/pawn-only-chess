import React, { useCallback, useEffect, useState } from "react";
import { createGame, fetchGame, postMove, restartGame } from "./api";

const FILES = "abcdefgh";
const STORAGE_KEY = "pawn_only_chess_game_id";

const squareName = (rank, file) => FILES[file] + (rank + 1);
const pieceAt = (board, rank, file) => {
  const ch = board[rank * 8 + file];
  return ch === "." ? null : ch;
};

function statusText(game, paused) {
  if (game.status === "draw") return "Game over: draw (no legal moves left).";
  if (game.status === "white_won" || game.status === "black_won") {
    return game.status === `${game.user_color}_won` ? "Game over: you win." : "Game over: the system wins.";
  }
  if (paused) return "Paused. Your game is saved; press Resume to continue.";
  if (game.turn !== game.user_color) return "System is thinking...";
  return `Your move. You play ${game.user_color}.`;
}

export default function App() {
  const [game, setGame] = useState(null);
  const [selected, setSelected] = useState(null);
  const [paused, setPaused] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);

  const adopt = useCallback((state) => {
    localStorage.setItem(STORAGE_KEY, state.id);
    setGame(state);
    setSelected(null);
    setError(null);
  }, []);

  const startGame = useCallback(
    async (color) => {
      setPaused(false);
      try {
        adopt(await createGame(color));
      } catch (e) {
        setError(e.message);
      }
    },
    [adopt]
  );

  useEffect(() => {
    const saved = localStorage.getItem(STORAGE_KEY);
    (saved ? fetchGame(saved).then(adopt) : Promise.reject())
      .catch(() => startGame("white"));
  }, [adopt, startGame]);

  if (!game) return <p>Loading...</p>;

  const userPiece = game.user_color === "white" ? "w" : "b";
  const playable = !paused && !busy && game.status === "in_progress" && game.turn === game.user_color;
  const targets = selected ? game.legal_moves.filter((m) => m.from === selected) : [];
  const userIsWhite = game.user_color === "white";
  const ranks = userIsWhite ? [7, 6, 5, 4, 3, 2, 1, 0] : [0, 1, 2, 3, 4, 5, 6, 7];
  const files = userIsWhite ? [0, 1, 2, 3, 4, 5, 6, 7] : [7, 6, 5, 4, 3, 2, 1, 0];
  const systemColor = game.user_color === "white" ? "black" : "white";

  const onSquare = async (sq, piece) => {
    if (!playable) return;
    const legal = selected && game.legal_moves.find((m) => m.from === selected && m.to === sq);
    if (legal) {
      setBusy(true);
      try {
        adopt(await postMove(game.id, selected, sq));
      } catch (e) {
        setError(e.message);
        setSelected(null);
      } finally {
        setBusy(false);
      }
      return;
    }
    setSelected(piece === userPiece && sq !== selected ? sq : null);
  };

  const restart = async () => {
    setPaused(false);
    try {
      adopt(await restartGame(game.id));
    } catch (e) {
      setError(e.message);
    }
  };

  const pairs = [];
  for (let i = 0; i < game.moves.length; i += 2) pairs.push([game.moves[i], game.moves[i + 1]]);
  const moveText = (m) => (m ? (m.capture ? `${m.from[0]}x${m.to}` : m.to) : "");

  return (
    <div>
      <h1>Pawn-Only Chess</h1>
      <p>Game ID: {game.id}</p>
      <p>{statusText(game, paused)}</p>
      {error && <p className="error">{error}</p>}

      <table className="board">
        <tbody>
          {ranks.map((rank) => (
            <tr key={rank}>
              <th>{rank + 1}</th>
              {files.map((file) => {
                const sq = squareName(rank, file);
                const piece = pieceAt(game.board, rank, file);
                const target = targets.find((t) => t.to === sq);
                return (
                  <td key={sq} className={selected === sq ? "sel" : undefined} onClick={() => onSquare(sq, piece)}>
                    {piece === "w" ? "♙" : piece === "b" ? "♟" : ""}
                    {target ? "·" : ""}
                  </td>
                );
              })}
            </tr>
          ))}
          <tr>
            <th></th>
            {files.map((file) => (
              <th key={file}>{FILES[file]}</th>
            ))}
          </tr>
        </tbody>
      </table>

      <p>
        Captured: you took {game.captured[systemColor]}, the system took {game.captured[game.user_color]}.
      </p>

      <p>
        <button onClick={restart}>Restart</button>{" "}
        <button onClick={() => startGame(game.user_color)}>New game</button>{" "}
        <button onClick={() => startGame(systemColor)}>New game as {systemColor}</button>{" "}
        <button onClick={() => setPaused((p) => !p)} disabled={game.status !== "in_progress"}>
          {paused ? "Resume" : "Pause"}
        </button>
      </p>

      <h2>Moves</h2>
      {pairs.length === 0 ? (
        <p>No moves yet. White plays first.</p>
      ) : (
        <ol>
          {pairs.map(([w, b], i) => (
            <li key={i}>
              {moveText(w)} {moveText(b)}
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}
