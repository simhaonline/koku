# Generated by Django 2.2.11 on 2020-04-15 21:28
from django.db import migrations
from django.db import models


class Migration(migrations.Migration):

    dependencies = [("reporting", "0110_summary_indexes")]

    operations = [
        migrations.RemoveIndex(model_name="awscostentrylineitemdailysummary", name="aws_summ_usage_pcode_like"),
        migrations.RemoveIndex(model_name="awscostentrylineitemdailysummary", name="aws_summ_usage_pfam_like"),
        migrations.AlterField(
            model_name="azurecostentryproductservice", name="service_name", field=models.TextField(null=True)
        ),
        migrations.AlterField(
            model_name="azurecostentryproductservice", name="service_tier", field=models.TextField(null=True)
        ),
    ]
