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

package dbseer.gui.frame;

import dbseer.gui.DBSeerGUI;
import net.miginfocom.swing.MigLayout;

import javax.swing.*;
import javax.swing.text.DefaultCaret;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

/**
 * Created by dyoon on 14. 11. 26..
 */
public class DBSeerShowTransactionExampleFrame extends JFrame implements ActionListener
{
	private JTextArea textArea = new JTextArea(40, 100);
	private JButton closeButton;
	private JButton nextButton;

	private int type;
	private int nextIndex;
	private String[] samples;

	public DBSeerShowTransactionExampleFrame(int type)
	{
		this.type = type;
		nextIndex = 0;
		initializeGUI();
		this.setTitle("View Transaction Examples");
	}

	private void initializeGUI()
	{
		this.setLayout(new MigLayout("fill"));
		DefaultCaret caret = (DefaultCaret)textArea.getCaret();
		caret.setUpdatePolicy(DefaultCaret.ALWAYS_UPDATE);

		textArea.setEditable(false);
		textArea.setLineWrap(true);
		JScrollPane scrollPane = new JScrollPane(textArea, JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED,
				JScrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED);
		scrollPane.setViewportView(textArea);
		scrollPane.setAutoscrolls(false);
		this.add(scrollPane, "grow, wrap");

		nextButton = new JButton("Next");
		nextButton.addActionListener(this);
		this.add(nextButton, "split 2, align center");

		closeButton = new JButton("Close");
		closeButton.addActionListener(this);
		this.add(closeButton);

		samples = DBSeerGUI.dbscan.getTransactionSamples(type);
//		try
//		{
//			String firstSample = DBSeerGUI.middlewareSocket.requestTransactionSample(type, nextIndex);
//			if (firstSample == null)
			if (samples == null || samples.length == 0)
			{
				textArea.setText("An example for this transaction type is not available.");
				nextButton.setEnabled(false);
			}
			else
			{
				String output = String.format("<Example #%d>\n", nextIndex + 1);
//				output += firstSample;
				output += samples[0];
				textArea.setText(output);
				nextIndex++;
			}
//		}
//		catch (IOException e)
//		{
//			DBSeerExceptionHandler.handleException(e);
//		}
	}

	@Override
	public void actionPerformed(ActionEvent actionEvent)
	{
		final JFrame frame = this;
		if (actionEvent.getSource() == closeButton)
		{
			SwingUtilities.invokeLater(new Runnable()
			{
				@Override
				public void run()
				{
					frame.dispose();
				}
			});
		}
		else if (actionEvent.getSource() == nextButton)
		{
//			String sample = null;
//			try
//			{
//				sample = DBSeerGUI.middlewareSocket.requestTransactionSample(type, nextIndex);
//			}
//			catch (IOException e)
//			{
//				DBSeerExceptionHandler.handleException(e);
//			}

			String output = textArea.getText();
			output += "\n\n";

//			if (sample == null)
			if (samples.length <= nextIndex)
			{
				output += "<End of transaction examples>";
				textArea.setText(output);
				nextButton.setEnabled(false);
			}
			else
			{
				output += String.format("<Example #%d>\n", nextIndex + 1);
//				output += sample;
				output += samples[nextIndex];
				textArea.setText(output);
				nextIndex++;
			}
		}
	}
}
