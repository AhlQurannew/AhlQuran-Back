import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/new_models/forms/guardian_form.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/services/network/api_endpoints.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/dialogs/guardian.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/management_grid.dart';
import 'package:the_doctarine_of_the_ppl_of_the_quran/system/widgets/management_show.dart';
import 'base_layout.dart';

class AddGuardian extends StatelessWidget {
  const AddGuardian({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffoldBackgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: BaseLayout(
        title: "Guardians Management",
        child: ManagementScreen<GuardianInfoDialog>(
          dataSourceEndpoint: ApiEndpoints.getSpecialGuardians,
          deleteEndpoint: (GuardianInfoDialog item) =>
              ApiEndpoints.getAccountInfoById(item.accountInfo.accountId),
          dialog: GuardianDialog(),
          managementType: ManagementTypes.guardians,
          rowBuilder: (guardian) => [
            DataGridCell<String>(
                columnName: 'id',
                value: guardian.accountInfo.accountId.toString()),
            DataGridCell<String>(
                columnName: 'first_name', value: guardian.guardian.firstName),
            DataGridCell<String>(
                columnName: 'last_name', value: guardian.guardian.lastName),
            DataGridCell<String>(
                columnName: 'date_of_birth',
                value: guardian.guardian.dateOfBirth),
            DataGridCell<String>(
                columnName: 'relationship',
                value: guardian.guardian.relationship),
            DataGridCell<String>(
                columnName: 'phone_number',
                value: guardian.contactInfo.phoneNumber),
            DataGridCell<String>(
                columnName: 'email', value: guardian.contactInfo.email),
            DataGridCell<String>(
                columnName: 'guardian_account',
                value: guardian.accountInfo.username),
            DataGridCell<String>(
                columnName: 'children',
                value: guardian.children.map((e) => e.firstNameAr).join(', ')),
            DataGridCell<String>(columnName: 'button', value: null),
          ],
          columnsNames: [
            GridColumn(
                columnName: 'id', label: ManagementGrid.buildHeader('ID')),
            GridColumn(
                columnName: 'first_name',
                label: ManagementGrid.buildHeader('First Name')),
            GridColumn(
                columnName: 'last_name',
                label: ManagementGrid.buildHeader('Last Name')),
            GridColumn(
                columnName: 'date_of_birth',
                label: ManagementGrid.buildHeader('Date of Birth')),
            GridColumn(
                columnName: 'relationship',
                label: ManagementGrid.buildHeader('Relationship')),
            GridColumn(
                columnName: 'phone_number',
                label: ManagementGrid.buildHeader('Phone')),
            GridColumn(
                columnName: 'email',
                label: ManagementGrid.buildHeader('Email')),
            GridColumn(
                columnName: 'guardian_account',
                label: ManagementGrid.buildHeader('Account')),
            GridColumn(
                columnName: 'children',
                label: ManagementGrid.buildHeader('Children')),
            GridColumn(
              columnName: 'button',
              label: ManagementGrid.buildHeader('Action'),
              allowSorting: false,
              allowFiltering: false,
            ),
          ],
        ),
      ),
    );
  }
}
