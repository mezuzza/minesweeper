import React, { useState } from 'react';
import { createUseStyles } from 'react-jss';

export enum CellState {
  UNKNOWN,
  FLAGGED,
  REVEALED,
}

type Props = {
  isBomb: boolean;
  numAdjacentBombs: number;
  row: number;
  column: number;
  state: CellState;
  onLeftClick: (r: number, c: number) => void;
  onRightClick: (r: number, c: number) => void;
};

const numToColor = (n: number) => {
  switch (n) {
    case 1:
      return 'blue';
    case 2:
      return 'green';
    case 3:
      return 'red';
    case 4:
      return 'darkblue';
    case 5:
      return 'darkred';
    case 6:
      return 'cyan';
    case 7:
      return 'black';
    case 8:
      return 'grey';
  }
};

const useStyles = createUseStyles({
  cell: (props: Props) => {
    let background: string | undefined;
    let border;
    let topLeftColor: string | undefined;
    let bottomRightColor: string | undefined;
    switch (props.state) {
      case CellState.UNKNOWN:
        topLeftColor = '#e6e6e6';
        bottomRightColor = '#b3b3b3';
        break;
      case CellState.FLAGGED:
        topLeftColor = '#e6e6e6';
        bottomRightColor = '#b3b3b3';
        background = 'url(flag.svg)';
        break;
      case CellState.REVEALED:
        topLeftColor = '#cccccc';
        bottomRightColor = '#cccccc';
        if (props.isBomb) {
          background = 'url(bomb.png)';
        }
        break;
    }
    return {
      width: 30,
      height: 30,

      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',

      fontFamily: 'monospace',
      fontSize: 'xx-large',
      color: numToColor(props.numAdjacentBombs),

      background: {
        color: '#cccccc',
        size: 'contain',
        image: background,
      },

      border: {
        width: 6,
        style: 'solid',
      },
      borderTopColor: topLeftColor,
      borderLeftColor: topLeftColor,
      borderBottomColor: bottomRightColor,
      borderRightColor: bottomRightColor,
    };
  },
});

export const Cell = (p: Props) => {
  const classes = useStyles(p);

  return (
    <div
      className={classes.cell}
      onClick={() => p.onLeftClick(p.row, p.column)}
      onContextMenu={(e) => {
        e.preventDefault();
        p.onRightClick(p.row, p.column);
      }}
    >
      {p.state === CellState.REVEALED && !p.isBomb && p.numAdjacentBombs > 0
        ? p.numAdjacentBombs
        : false}
    </div>
  );
};
