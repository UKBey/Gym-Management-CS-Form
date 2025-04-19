using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Npgsql;

namespace GymManagement
{
    public partial class MembershipPlanForm : Form
    {
        public MembershipPlanForm()
        {
            InitializeComponent();
        }
        NpgsqlConnection connect = new NpgsqlConnection("server=localHost; port=5432;UserId = postgres;" + "password=321654;database=gym_management");

        private void btnAdd_Click(object sender, EventArgs e)
        {
            try
            {
                connect.Open();
                NpgsqlCommand command1 = new NpgsqlCommand("insert into MembershipPlans (PlanName, Price, DurationMonths) values(@name, @price, @duration)", connect);
                command1.Parameters.AddWithValue("@name", boxName.Text);
                command1.Parameters.AddWithValue("@price", decimal.Parse(boxPrice.Text));
                command1.Parameters.AddWithValue("@duration", int.Parse(boxMonths.Text));
                command1.ExecuteNonQuery();
                MessageBox.Show("Membership Plan Has Been Added Successfully");
                btnList_Click(null, null);
            }
            catch (FormatException)
            {
                MessageBox.Show("Please fill in the information completely and in the correct format.");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error while adding membership plan: " + ex.Message);
            }
            finally
            {
                connect.Close();
            }
        }

        private void btnList_Click(object sender, EventArgs e)
        {
            try
            {
                string query = "select * from MembershipPlans";
                NpgsqlDataAdapter adapt = new NpgsqlDataAdapter(query, connect);
                DataSet ds = new DataSet();
                adapt.Fill(ds);
                dataGridView1.DataSource = ds.Tables[0];
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error while listing membership plans: " + ex.Message);
            }
        }

        private void btnUpdate_Click(object sender, EventArgs e)
        {
            if (dataGridView1.SelectedRows.Count > 0)
            {
                try
                {
                    int planID = int.Parse(dataGridView1.SelectedRows[0].Cells["PlanID"].Value.ToString());
                    string planName = dataGridView1.SelectedRows[0].Cells["PlanName"].Value.ToString();
                    decimal price = decimal.Parse(dataGridView1.SelectedRows[0].Cells["Price"].Value.ToString());
                    int duration = int.Parse(dataGridView1.SelectedRows[0].Cells["DurationMonths"].Value.ToString());

                    connect.Open();
                    string query = "UPDATE MembershipPlans SET PlanName = @name, Price = @price, DurationMonths = @duration WHERE PlanID = @id";
                    NpgsqlCommand command = new NpgsqlCommand(query, connect);
                    command.Parameters.AddWithValue("@id", planID);
                    command.Parameters.AddWithValue("@name", planName);
                    command.Parameters.AddWithValue("@price", price);
                    command.Parameters.AddWithValue("@duration", duration);

                    command.ExecuteNonQuery();
                    MessageBox.Show("Selected membership plan has been updated successfully!");
                    btnList_Click(null, null);
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error while updating membership plan: " + ex.Message);
                }
                finally
                {
                    connect.Close();
                }
            }
            else
            {
                MessageBox.Show("Please select a row to update.");
            }
        }

        private void btnDel_Click(object sender, EventArgs e)
        {
            if (dataGridView1.SelectedRows.Count > 0)
            {
                try
                {
                    int planID = int.Parse(dataGridView1.SelectedRows[0].Cells["PlanID"].Value.ToString());

                    connect.Open();
                    string query = "DELETE FROM MembershipPlans WHERE PlanID = @id";
                    NpgsqlCommand command = new NpgsqlCommand(query, connect);
                    command.Parameters.AddWithValue("@id", planID);
                    command.ExecuteNonQuery();
                    MessageBox.Show("Selected membership plan has been deleted successfully!");
                    btnList_Click(null, null);
                }
                catch (PostgresException) 
                {
                    MessageBox.Show("This membership plan is currently in use and cannot be deleted.");
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Error while deleting membership plan: " + ex.Message);
                }
                finally
                {
                    connect.Close();
                }
            }
            else
            {
                MessageBox.Show("Please select a row to delete.");
            }
        }

    }
}
