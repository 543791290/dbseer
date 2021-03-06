/*
 * Copyright 2013 Barzan Mozafari
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package dbseer.gui.panel;

import dbseer.comp.process.live.LiveMonitorInfo;
import dbseer.gui.DBSeerExceptionHandler;
import dbseer.gui.DBSeerGUI;
import dbseer.gui.frame.DBSeerShowTransactionExampleFrame;
import dbseer.gui.user.DBSeerDataSet;
import net.miginfocom.swing.MigLayout;
import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.ValueAxis;
import org.jfree.chart.plot.XYPlot;
import org.jfree.chart.renderer.xy.XYItemRenderer;
import org.jfree.data.time.Millisecond;
import org.jfree.data.time.TimeSeries;
import org.jfree.data.time.TimeSeriesCollection;
import org.jfree.data.xy.XYDataset;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;

/**
 * Created by dyoon on 5/17/15.
 */
public class DBSeerLiveMonitorPanel extends JPanel implements ActionListener
{
	private ChartPanel throughputChartPanel;
	private ChartPanel latencyChartPanel;

	private JPanel leftDockPanel;
	private JPanel rightPanel;
	private JPanel transactionTypesPanel;

	private JTable monitorTable;
	private int numTransactionType;
	private ArrayList<String> transactionNames;
	private ArrayList<JLabel> transactionLabels;
	private ArrayList<JButton> transactionDeleteButtons;
	private ArrayList<JButton> transactionRenameButtons;
	private ArrayList<JButton> transactionViewSampleButtons;
	private ArrayList<JButton> transactionEnableDisableButtons;

	private TimeSeriesCollection throughputCollection;
	private TimeSeriesCollection latencyCollection;

	private static final int ROW_PER_TX_TYPE = 2;

	private static String[] tableHeaders = {
			"Total number of transactions processed",
			"Current throughput (TPS)",
	};


	public DBSeerLiveMonitorPanel()
	{
		this.setLayout(new MigLayout("fill"));

		numTransactionType = 0;
		transactionNames = new ArrayList<String>();
		monitorTable = new JTable(new DefaultTableModel(null, new String[]{"Name", "Value"}) {
			@Override
			public boolean isCellEditable(int i, int i1)
			{
				return false;
			}
		});

		monitorTable.setFillsViewportHeight(true);
		monitorTable.getColumnModel().getColumn(0).setMaxWidth(1200);
		monitorTable.getColumnModel().getColumn(0).setPreferredWidth(1200);
		monitorTable.getColumnModel().getColumn(1).setMaxWidth(200);
		monitorTable.getColumnModel().getColumn(1).setPreferredWidth(200);
		monitorTable.setRowHeight(20);

		for (String header : tableHeaders)
		{
			DefaultTableModel model = (DefaultTableModel) monitorTable.getModel();
			model.addRow(new Object[]{header, "0.0"});
		}

		transactionLabels = new ArrayList<JLabel>();
		transactionDeleteButtons = new ArrayList<JButton>();
		transactionRenameButtons = new ArrayList<JButton>();
		transactionViewSampleButtons = new ArrayList<JButton>();
		transactionEnableDisableButtons = new ArrayList<JButton>();

		initialize();
	}

	private void initialize()
	{
		JScrollPane tableScrollPane = new JScrollPane(monitorTable);
		tableScrollPane.setPreferredSize(new Dimension(300,300));
		JScrollPane transactionTypesScrollPane = new JScrollPane();
		leftDockPanel = new JPanel();
		leftDockPanel.setLayout(new MigLayout("fill"));
		transactionTypesPanel = new JPanel();
		transactionTypesPanel.setLayout(new MigLayout("wrap 3"));
		rightPanel = new JPanel();
		rightPanel.setLayout(new MigLayout("fill"));
		rightPanel.setPreferredSize(new Dimension(640,480));

		transactionTypesScrollPane.setViewportView(transactionTypesPanel);
		transactionTypesScrollPane.setBorder(BorderFactory.createTitledBorder("Transaction types"));
		transactionTypesScrollPane.setPreferredSize(new Dimension(360,300));

		throughputCollection = new TimeSeriesCollection();
		throughputChartPanel = new ChartPanel(createThroughputChart(throughputCollection));

		latencyCollection = new TimeSeriesCollection();
		latencyChartPanel = new ChartPanel(createAverageLatencyChart(latencyCollection));

		leftDockPanel.add(tableScrollPane, "wrap, grow");
		leftDockPanel.add(transactionTypesScrollPane, "grow");

		rightPanel.add(throughputChartPanel, "grow, wrap");
		rightPanel.add(latencyChartPanel, "grow");

		this.add(leftDockPanel, "dock west, growy");
		this.add(rightPanel, "grow");
	}

	public void reset()
	{
		synchronized (LiveMonitorInfo.LOCK)
		{
			DefaultTableModel model = (DefaultTableModel) monitorTable.getModel();
			int rowCount = model.getRowCount();
			for (int i = rowCount-1; i >= 2; --i)
			{
				model.removeRow(i);
			}
			latencyCollection.removeAllSeries();
			throughputCollection.removeAllSeries();
			for (JLabel label : transactionLabels)
			{
				transactionTypesPanel.remove(label);
			}
			transactionLabels.clear();
			for (JButton button : transactionRenameButtons)
			{
				transactionTypesPanel.remove(button);
			}
			transactionRenameButtons.clear();
			for (JButton button : transactionViewSampleButtons)
			{
				transactionTypesPanel.remove(button);
			}
			transactionViewSampleButtons.clear();
			for (JButton button : transactionEnableDisableButtons)
			{
				transactionTypesPanel.remove(button);
			}
			transactionEnableDisableButtons.clear();
			transactionNames.clear();
			numTransactionType = 0;

			setTotalNumberOfTransactions(0.0);
			setCurrentTPS(0.0);
		}
		this.invalidate();
		this.repaint();
	}

	public void setTotalNumberOfTransactions(double total)
	{
		DefaultTableModel model = (DefaultTableModel) monitorTable.getModel();
		model.setValueAt(String.format("%.0f", total), 0, 1);
	}

	public void setCurrentTPS(double tps)
	{
		DefaultTableModel model = (DefaultTableModel) monitorTable.getModel();
		model.setValueAt(String.format("%.1f", tps), 1, 1);
	}

	public synchronized void setCurrentTPS(long time, int index, double tps)
	{
		synchronized (LiveMonitorInfo.LOCK)
		{
			DefaultTableModel model = (DefaultTableModel) monitorTable.getModel();
			if (model.getRowCount() <= 2 + (index * ROW_PER_TX_TYPE))
			{
				model.addRow(new Object[]{"", ""});
			}
			model.setValueAt(String.format("%.1f", tps), 2 + (index * ROW_PER_TX_TYPE), 1);
			if (numTransactionType < index + 1)
			{
				String newName = "Type " + (index + 1);
				transactionNames.add(newName);
				numTransactionType = index + 1;

				JLabel newLabel = new JLabel(newName);
				JButton renameButton = new JButton("Rename");
				JButton viewSampleButton = new JButton("View Examples");
//				JButton enableDisableButton;
//				if (DBSeerGUI.liveDataset.isTransactionEnabled(index))
//				{
//					enableDisableButton = new JButton("Disable");
//				}
//				else
//				{
//					enableDisableButton = new JButton("Enable");
//				}

				renameButton.addActionListener(this);
				viewSampleButton.addActionListener(this);
//				enableDisableButton.addActionListener(this);

				transactionTypesPanel.add(newLabel);
				transactionTypesPanel.add(renameButton);
				transactionTypesPanel.add(viewSampleButton);
//				transactionTypesPanel.add(enableDisableButton);

				transactionLabels.add(newLabel);
				transactionRenameButtons.add(renameButton);
				transactionViewSampleButtons.add(viewSampleButton);
//				transactionEnableDisableButtons.add(enableDisableButton);

				for (DBSeerDataSet dataset : DBSeerGUI.liveDatasets)
				{
					dataset.addTransactionType("Type " + numTransactionType);
				}

//			TimeSeriesCollection newThroughputCollection = new TimeSeriesCollection(new TimeSeries(newName, Millisecond.class));
//			TimeSeriesCollection collection = (TimeSeriesCollection) throughputChartPanel.getChart().getXYPlot().getDataset();
				throughputCollection.addSeries(new TimeSeries(newName, Millisecond.class));
				latencyCollection.addSeries(new TimeSeries(newName, Millisecond.class));

//			throughputChartPanel.getChart().getXYPlot().setDataset(index, newThroughputCollection);

				this.revalidate();
				this.repaint();
			}
			model.setValueAt(String.format("Current TPS of '%s' transactions", transactionNames.get(index)),
					2 + (index * ROW_PER_TX_TYPE), 0);

//		TimeSeriesCollection collection = (TimeSeriesCollection) throughputChartPanel.getChart().getXYPlot().getDataset();
			if (index < throughputCollection.getSeriesCount())
			{
				TimeSeries series = throughputCollection.getSeries(index);
//				series.add(new Millisecond(), tps);
				series.addOrUpdate(new Millisecond(new Date(time * 1000)), tps);
			}
		}
	}

	public synchronized void setCurrentAverageLatency(long time, int index, double latency)
	{
		synchronized (LiveMonitorInfo.LOCK)
		{
			DefaultTableModel model = (DefaultTableModel) monitorTable.getModel();
			if (model.getRowCount() <= 2 + (index * ROW_PER_TX_TYPE + 1))
			{
				model.addRow(new Object[]{"", ""});
			}
			model.setValueAt(String.format("%.1f", latency), 2 + (index * ROW_PER_TX_TYPE) + 1, 1);
			if (numTransactionType < index + 1)
			{
				String newName = "Type " + (index + 1);
				transactionNames.add(newName);
				numTransactionType = index + 1;

				JLabel newLabel = new JLabel(newName);
				JButton renameButton = new JButton("Rename");
				JButton viewSampleButton = new JButton("View Examples");
//				JButton enableDisableButton;
//				if (DBSeerGUI.liveDataset.isTransactionEnabled(index))
//				{
//					enableDisableButton = new JButton("Disable");
//				}
//				else
//				{
//					enableDisableButton = new JButton("Enable");
//				}

				renameButton.addActionListener(this);
				viewSampleButton.addActionListener(this);
//				enableDisableButton.addActionListener(this);

				transactionTypesPanel.add(newLabel);
				transactionTypesPanel.add(renameButton);
				transactionTypesPanel.add(viewSampleButton);
//				transactionTypesPanel.add(enableDisableButton);

				transactionLabels.add(newLabel);
				transactionRenameButtons.add(renameButton);
				transactionViewSampleButtons.add(viewSampleButton);
//				transactionEnableDisableButtons.add(enableDisableButton);

				throughputCollection.addSeries(new TimeSeries(newName, Millisecond.class));
				latencyCollection.addSeries(new TimeSeries(newName, Millisecond.class));

				this.revalidate();
				this.repaint();
			}
			model.setValueAt(String.format("Current average latency of '%s' transactions", transactionNames.get(index)),
					2 + (index * ROW_PER_TX_TYPE) + 1, 0);

			if (index < latencyCollection.getSeriesCount())
			{
				TimeSeries series = latencyCollection.getSeries(index);
//				series.add(new Millisecond(), latency);
				series.addOrUpdate(new Millisecond(new Date(time * 1000)), latency);
			}
		}
	}

	public synchronized void updateTransactionNames()
	{
		if (DBSeerGUI.liveDataset.getTransactionTypes().size() == 0)
		{
			return;
		}

		for (int i = 0; i < transactionRenameButtons.size(); ++i)
		{
			String newName = DBSeerGUI.liveDataset.getTransactionTypes().get(i).getName();

			newName = newName.trim();
			transactionLabels.get(i).setText(newName);
			transactionNames.set(i, newName);

			DefaultTableModel model = (DefaultTableModel) monitorTable.getModel();
			model.setValueAt(String.format("Current TPS of '%s' transactions", newName),
					2+(i*ROW_PER_TX_TYPE), 0);
			model.setValueAt(String.format("Current average latency of '%s' transactions", newName),
					2 + (i * ROW_PER_TX_TYPE) + 1, 0);

			throughputCollection.getSeries(i).setKey(newName);
			latencyCollection.getSeries(i).setKey(newName);

			return;
		}
	}

	@Override
	public synchronized void actionPerformed(ActionEvent event)
	{
		for (int i = 0; i < transactionRenameButtons.size(); ++i)
		{
			if (event.getSource() == transactionRenameButtons.get(i))
			{
				String newName = (String)JOptionPane.showInputDialog(this, "Enter the new name for this transaction type", "New Dataset",
						JOptionPane.PLAIN_MESSAGE, null, null, transactionNames.get(i));

				if (newName == null || newName.trim().isEmpty())
				{
					return;
				}
				else
				{
					newName = newName.trim();
					transactionNames.set(i, newName);
					transactionLabels.get(i).setText(newName);

					DefaultTableModel model = (DefaultTableModel) monitorTable.getModel();
					model.setValueAt(String.format("Current TPS of '%s' transactions", transactionNames.get(i)),
							2+(i*ROW_PER_TX_TYPE), 0);
					model.setValueAt(String.format("Current average latency of '%s' transactions", transactionNames.get(i)),
							2 + (i * ROW_PER_TX_TYPE) + 1, 0);

//					TimeSeriesCollection collection = (TimeSeriesCollection) throughputChartPanel.getChart().getXYPlot().getDataset();
					throughputCollection.getSeries(i).setKey(newName);
					latencyCollection.getSeries(i).setKey(newName);

//					if (DBSeerGUI.currentDataset != null)
//					{
//						DBSeerGUI.currentDataset.setTransactionTypeName(i, newName);
//					}

					for (DBSeerDataSet dataset : DBSeerGUI.liveDatasets)
					{
						dataset.setTransactionTypeName(i, newName);
					}

					return;
				}
			}
		}

		for (int i = 0; i < transactionViewSampleButtons.size(); ++i)
		{
			if (event.getSource() == transactionViewSampleButtons.get(i))
			{
				final int type = i;
				SwingUtilities.invokeLater(new Runnable()
				{
					@Override
					public void run()
					{
						DBSeerShowTransactionExampleFrame sampleFrame = new DBSeerShowTransactionExampleFrame(type);
						sampleFrame.pack();
						sampleFrame.setLocationRelativeTo(DBSeerGUI.mainFrame);
						sampleFrame.setVisible(true);
					}
				});
			}
		}

		for (int i = 0; i < transactionEnableDisableButtons.size(); ++i)
		{
			if (event.getSource() == transactionEnableDisableButtons.get(i))
			{
				final XYItemRenderer throughputRenderer = throughputChartPanel.getChart().getXYPlot().getRenderer();
				final XYItemRenderer latencyRenderer = latencyChartPanel.getChart().getXYPlot().getRenderer();
				final int type = i;
				final JButton button = transactionEnableDisableButtons.get(i);
				final DBSeerDataSet dataset = DBSeerGUI.liveDataset;

				SwingUtilities.invokeLater(new Runnable()
				{
					@Override
					public void run()
					{
						if (button.getText() == "Disable")
						{
							dataset.disableTransaction(type);
							throughputRenderer.setSeriesVisible(type, false);
							latencyRenderer.setSeriesVisible(type, false);
							button.setText("Enable");
						}
						else if (button.getText() == "Enable")
						{
							dataset.enableTransaction(type);
							throughputRenderer.setSeriesVisible(type, true);
							latencyRenderer.setSeriesVisible(type, true);
							button.setText("Disable");
						}
					}
				});
			}
		}

		for (int i = 0; i < transactionDeleteButtons.size(); ++i)
		{
			if (event.getSource() == transactionDeleteButtons.get(i))
			{
				synchronized (LiveMonitorInfo.LOCK)
				{
					try
					{
						DBSeerGUI.middlewareSocket.removeTransactionType(i);
					}
					catch (IOException e)
					{
						DBSeerExceptionHandler.handleException(e);
					}

					throughputCollection.removeSeries(i);
					latencyCollection.removeSeries(i);

					DefaultTableModel model = (DefaultTableModel) monitorTable.getModel();
					int newTxSize = transactionNames.size() - 1;
					for (int j = 0; j < transactionNames.size(); ++j)
					{
						model.setValueAt(String.format("Current TPS of '%s' transactions", transactionNames.get(j)),
								2 + (j * ROW_PER_TX_TYPE), 0);
						model.setValueAt(String.format("Current average latency of '%s' transactions", transactionNames.get(j)),
								2 + (j * ROW_PER_TX_TYPE) + 1, 0);
						model.setValueAt("",
								2 + (j * ROW_PER_TX_TYPE), 1);
						model.setValueAt("",
								2 + (j * ROW_PER_TX_TYPE) + 1, 1);
					}
					model.setValueAt("", 2 + (newTxSize * ROW_PER_TX_TYPE), 0);
					model.setValueAt("", 2 + (newTxSize * ROW_PER_TX_TYPE), 1);
					model.setValueAt("", 2 + (newTxSize * ROW_PER_TX_TYPE) + 1, 0);
					model.setValueAt("", 2 + (newTxSize * ROW_PER_TX_TYPE) + 1, 1);

					final JPanel panel = transactionTypesPanel;
					final JLabel label = transactionLabels.remove(i);
					final JButton renameButton = transactionRenameButtons.remove(i);
					final JButton exampleButton = transactionViewSampleButtons.remove(i);
					final JButton deleteButton = transactionDeleteButtons.remove(i);
					transactionNames.remove(i);

					SwingUtilities.invokeLater(new Runnable()
					{
						@Override
						public void run()
						{
							panel.remove(label);
							panel.remove(renameButton);
							panel.remove(exampleButton);
							panel.remove(deleteButton);

							panel.revalidate();
							panel.repaint();
						}
					});
				}
				break;
			}
		}

	}

	private JFreeChart createThroughputChart(final XYDataset dataset) {
		final JFreeChart result = ChartFactory.createTimeSeriesChart(
				"Current Throughput",
				"Time",
				"TPS",
				dataset,
				true,
				true,
				false
		);
		final XYPlot plot = result.getXYPlot();
		ValueAxis axis = plot.getDomainAxis();
		axis.setAutoRange(true);
		axis.setFixedAutoRange(300000.0);  // 300 seconds = 5 min
		axis = plot.getRangeAxis();
		axis.setAutoRange(true);
//		axis.setRange(0.0, 100.0);
		return result;
	}

	private JFreeChart createAverageLatencyChart(final XYDataset dataset) {
		final JFreeChart result = ChartFactory.createTimeSeriesChart(
				"Current Latency",
				"Time",
				"Latency (ms)",
				dataset,
				true,
				true,
				false
		);
		final XYPlot plot = result.getXYPlot();
		ValueAxis axis = plot.getDomainAxis();
		axis.setAutoRange(true);
		axis.setFixedAutoRange(300000.0);  // 300 seconds = 5 min
		axis = plot.getRangeAxis();
		axis.setAutoRange(true);
//		axis.setRange(0.0, 500.0);
		return result;
	}
}
