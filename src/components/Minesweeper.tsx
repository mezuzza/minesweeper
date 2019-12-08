import React, { useState } from 'react';
import { createUseStyles } from 'react-jss';
import * as _ from 'lodash';
import { Random, MersenneTwister19937 } from 'random-js';
import * as Rand from 'random-js';

import { Cell, CellState } from 'components/Cell';

const MT_ENGINE = MersenneTwister19937.autoSeed();

const useStyles = createUseStyles({
  grid: {
    display: 'grid',
    width: 'fit-content',
    height: 'auto',
    gridTemplateColumns: 'auto',
    gridTemplateRows: 'repeat(10, auto)',

    borderStyle: 'solid',
    borderWidth: 10,
    borderColor: 'grey',
  },
  row: {
    display: 'grid',
    width: 'auto',
    height: 'auto',
    gridTemplateColumns: 'repeat(10, auto)',
    gridTemplateRows: 'auto',
  },
});

type Props = {
  rows: number;
  columns: number;
  numBombs: number;
};

const chooseBombLocations = (p: Props) => {
  let locations = new Set<number>();
  const distribution = Rand.integer(0, p.rows * p.columns - 1);
  while (locations.size < p.numBombs) {
    locations.add(distribution(MT_ENGINE));
  }
  return locations;
};

export const Minesweeper = (p: Props) => {
  const classes = useStyles();
  const [bombLocations] = useState(() => chooseBombLocations(p));
  const [cellStates, setCellStates] = useState(() =>
    _.times(p.rows, () => _.times(p.columns, () => CellState.UNKNOWN)),
  );

  const cellIsBomb = (r: number, c: number) => {
    return bombLocations.has(p.columns * r + c);
  };

  const numAdjacentBombs = (r: number, c: number): number => {
    let count = 0;
    for (let i of [-1, 0, 1]) {
      for (let j of [-1, 0, 1]) {
        if (
          // Rows in bounds
          0 <= r + i &&
          r + i < p.rows &&
          // Column in bounds
          0 <= c + j &&
          c + j < p.columns &&
          // Don't check yourself
          !(i === 0 && j === 0) &&
          cellIsBomb(r + i, c + j)
        ) {
          count += 1;
        }
      }
    }

    return count;
  };

  const revealCell = (cellStates: CellState[][], r: number, c: number) => {
    console.log('Revealing (', r, ', ', c, ')');
    cellStates[r][c] = CellState.REVEALED;
    // Current cell not bomb
    if (cellIsBomb(r, c)) {
      return cellStates;
    }

    if (numAdjacentBombs(r, c) === 0) {
      for (let i of [-1, 0, 1]) {
        for (let j of [-1, 0, 1]) {
          if (
            // Rows in bounds
            0 <= r + i &&
            r + i < p.rows &&
            // Column in bounds
            0 <= c + j &&
            c + j < p.columns &&
            // Cell Unopened
            cellStates[r + i][c + j] === CellState.UNKNOWN
          ) {
            cellStates = revealCell(cellStates, r + i, c + j);
          }
        }
      }
    }

    return cellStates;
  };

  const handleLeftClick = (r: number, c: number) => {
    if (cellStates[r][c] === CellState.UNKNOWN) {
      setCellStates([...revealCell(cellStates, r, c)]);
    }
  };

  const handleRightClick = (r: number, c: number) => {
    switch (cellStates[r][c]) {
      case CellState.UNKNOWN:
        cellStates[r][c] = CellState.FLAGGED;
        break;
      case CellState.FLAGGED:
        cellStates[r][c] = CellState.UNKNOWN;
        break;
    }
    setCellStates([...cellStates]);
  };

  const rows = _.times(p.rows, (r) => {
    let cells = _.times(p.columns, (c) => (
      <Cell
        key={c}
        isBomb={cellIsBomb(r, c)}
        numAdjacentBombs={numAdjacentBombs(r, c)}
        row={r}
        column={c}
        state={cellStates[r][c]}
        onLeftClick={handleLeftClick}
        onRightClick={handleRightClick}
      />
    ));
    return (
      <div key={r} className={classes.row}>
        {cells}
      </div>
    );
  });

  return <div className={classes.grid}>{rows}</div>;
};
