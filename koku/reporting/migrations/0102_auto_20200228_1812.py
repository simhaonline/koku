# Generated by Django 2.2.10 on 2020-02-28 18:12
import django.contrib.postgres.fields.jsonb
from django.db import migrations
from django.db import models


class Migration(migrations.Migration):

    dependencies = [("reporting", "0101_ocpenabledtagkeys")]

    operations = [
        migrations.RemoveField(model_name="ocpusagelineitemdailysummary", name="infra_cost"),
        migrations.RemoveField(model_name="ocpusagelineitemdailysummary", name="markup_cost"),
        migrations.RemoveField(model_name="ocpusagelineitemdailysummary", name="monthly_cost"),
        migrations.RemoveField(
            model_name="ocpusagelineitemdailysummary", name="persistentvolumeclaim_charge_gb_month"
        ),
        migrations.RemoveField(model_name="ocpusagelineitemdailysummary", name="pod_charge_cpu_core_hours"),
        migrations.RemoveField(model_name="ocpusagelineitemdailysummary", name="pod_charge_memory_gigabyte_hours"),
        migrations.RemoveField(model_name="ocpusagelineitemdailysummary", name="project_infra_cost"),
        migrations.RemoveField(model_name="ocpusagelineitemdailysummary", name="project_markup_cost"),
        migrations.AddField(
            model_name="ocpusagelineitemdailysummary",
            name="infrastructure_markup_cost",
            field=models.DecimalField(decimal_places=15, max_digits=33, null=True),
        ),
        migrations.AddField(
            model_name="ocpusagelineitemdailysummary",
            name="infrastructure_monthly_cost",
            field=models.DecimalField(decimal_places=15, max_digits=33, null=True),
        ),
        migrations.AddField(
            model_name="ocpusagelineitemdailysummary",
            name="infrastructure_project_markup_cost",
            field=models.DecimalField(decimal_places=15, max_digits=33, null=True),
        ),
        migrations.AddField(
            model_name="ocpusagelineitemdailysummary",
            name="infrastructure_project_raw_cost",
            field=models.DecimalField(decimal_places=15, max_digits=33, null=True),
        ),
        migrations.AddField(
            model_name="ocpusagelineitemdailysummary",
            name="infrastructure_raw_cost",
            field=models.DecimalField(decimal_places=15, max_digits=33, null=True),
        ),
        migrations.AddField(
            model_name="ocpusagelineitemdailysummary",
            name="infrastructure_usage_cost",
            field=django.contrib.postgres.fields.jsonb.JSONField(null=True),
        ),
        migrations.AddField(
            model_name="ocpusagelineitemdailysummary",
            name="monthly_cost_type",
            field=models.TextField(choices=[("Node", "Node"), ("Cluster", "Cluster")], null=True),
        ),
        migrations.AddField(
            model_name="ocpusagelineitemdailysummary",
            name="supplementary_monthly_cost",
            field=models.DecimalField(decimal_places=15, max_digits=33, null=True),
        ),
        migrations.AddField(
            model_name="ocpusagelineitemdailysummary",
            name="supplementary_usage_cost",
            field=django.contrib.postgres.fields.jsonb.JSONField(null=True),
        ),
    ]
